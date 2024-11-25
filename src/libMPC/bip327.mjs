/********************************************************************************************/
/*
/*     ___                _   _       ___               _         _    _ _    
/*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
/*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
/*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
/*                                         |__/|_|           
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
/* License: This software is licensed under MIT License                                        
/********************************************************************************************/
// Use import instead of require in ES modules
import { etc, utils, getPublicKey } from '@noble/secp256k1';
import { randomBytes } from 'crypto'; // Use Node.js's crypto module

import {  secp256k1 } from '@noble/curves/secp256k1'; // ESM and Common.js
const {mod, ProjectivePoint} = secp256k1;
const {assertValidity} = ProjectivePoint;

import { hmac } from '@noble/hashes/hmac';
import { createHash } from 'crypto';


//TODO: remplace errors by errcodes;

/********************************************************************************************/
/* GENERAL FUNCTIONS*/   
/********************************************************************************************/
// Access Field from secp256k1
const { Field } = secp256k1;

// Function to compute sha256 hash
export function sha256(data) {
  return createHash('sha256').update(data).digest();
}

function bytesToHex(bytes) {
  return Buffer.from(bytes).toString('hex');
}

// Tagged hash function compliant with BIP327
// tag: str
// message: bytes 
export function tagged_hashBTC(tag, message) {
  // Convert the tag to a sha256 hash (as bytes)
  const tagHash = sha256(Buffer.from(tag, 'utf-8'));
  
  // Concatenate (encodePacked) tagHash, tagHash, and the message
  const encoded = Buffer.concat([tagHash, tagHash, message]);
 
  // Compute final sha256 hash
  const finalHash = sha256(encoded);
  
  return finalHash;
}

function bytes_xor(a,b){
  if (a.length !== b.length) {
    throw new Error('Byte arrays must be of the same length');
  }
  let c=a;
  for(let i=0;i<a.length;i++)
    c[i]^=b[i];

  return c;
}


export function  IndividualPubKey_array(scalar_array){
  const publicKey = getPublicKey(scalar_array); // 'true' for compressed format
  
  return publicKey;
}

export function  IndividualPubKey(scalar){
  const publicKey = getPublicKey(scalar, true); // 'true' for compressed format
  
  return publicKey;
}

//convert bytes to bigInt
export function int_from_bytes(bytes){
  return BigInt('0x' + Buffer.from(bytes).toString('hex'));
}

//return second public key, in order to implement Musig2* trick
function get_second_key(pubkeys){
  let u=pubkeys.length;
  for(let j =0; j<u;j++ )
    if(pubkeys[j] != pubkeys[0])
      return pubkeys[j];
    return 0;//there is no second Pubkey 
}

//hash the concatenation of public keys
//tagged_hashBTC:bytes
export function hash_keys(pubkeys){
   // Concatenate the list of public keys (byte arrays)
   const concatenatedPubkeys = Buffer.concat(pubkeys);
  
   // Use the tagged_hash function with the specified tag and concatenated public keys
   return tagged_hashBTC('KeyAgg list', concatenatedPubkeys);
}

//compression, with infinity case as zeroes
function cbytes_ext(Point){

  if(secp256k1.ProjectivePoint.ZERO.equals(Point)) 
   return Buffer.from("000000000000000000000000000000000000000000000000000000000000000000",'hex');//infty encoded as  "OO" vector of size 33
  
  return Point.toRawBytes();
   
 }

function has_even_y(RawHex_Point){
  if(RawHex_Point[0]==0x03)
  {
    return false;
  }
  else 
    return true;
}

/********************************************************************************************/
/* KEY AGGREGATION FUNCTIONS*/   
/********************************************************************************************/


//return the ai coefficient 
function key_agg_coeff_internal(pubkeys, pki, pk2){
  let L = hash_keys(pubkeys);
 
  if (Buffer.from(pki).equals(pk2))
        {
          return BigInt('0x1');
        }
  return int_from_bytes(tagged_hashBTC('KeyAgg coefficient', Buffer.concat([L , pki])))  % secp256k1.CURVE.n
}

//return the ai coefficient using Musig2* trick 
export function key_agg_coeff(pubkeys, pki){
  let pk2=get_second_key(pubkeys);
 
  return key_agg_coeff_internal(pubkeys, pki, pk2)
}

//only for keyagg, nonceagg and getsession_values, if a point is odd, then its negation is taken
//input is 33 bytes compressed key with parity
function cpoint(bytePoint){
 
  let P=secp256k1.ProjectivePoint.fromHex(bytePoint);
  
  return P;
}


// Function equivalent test if point is infinity, if not return even point
function cpoint_ext(Point) {
 

    return cpoint(Point);
}

//the key aggregation function, prior to tweak
//pubkeys is a list of point (for now)
export function key_agg(pubkeys){
  let pk2=get_second_key(pubkeys)
  let u=pubkeys.length;
  let Q = secp256k1.ProjectivePoint.ZERO;//infinity neutral point
  let P= secp256k1.ProjectivePoint.BASE;
  for(let i=0;i<u;i++){
    let Pi=cpoint(pubkeys[i]);
   
    if(Pi==false)
      return false;
    let ai=key_agg_coeff_internal(pubkeys, pubkeys[i], pk2);
  
  
    Q = Q.add( Pi.multiply(ai));//Q=Q+aiPi  
   
  }
  if(Q==secp256k1.ProjectivePoint.ZERO)
    return false;

  return [Q.toRawBytes(),BigInt(1),BigInt(0)]; //(Q,gacc,tacc), this is a key_aggCtx
}



/********************************************************************************************/
/* TWEAKING FUNCTIONS*/   
/********************************************************************************************/
export function apply_tweak(key_aggCtx, tweak, is_xonly){

  if(tweak.length!=32) return false;
  let t = int_from_bytes(tweak);
  if(t>secp256k1.CURVE.n) return false;
  let Q=ProjectivePoint.fromHex(key_aggCtx[0]);
  let P= secp256k1.ProjectivePoint.BASE;//base Point
  let g=BigInt('0x1') ;


  if(is_xonly&& (has_even_y(key_aggCtx[0])==false)){
    Q=Q.negate();
    g=secp256k1.CURVE.n-g;//n-1
  }

  Q=Q.add(P.multiply(t));//Q=Q+t.P
  let gacc_ = (g * key_aggCtx[1] ) % secp256k1.CURVE.n
  let tacc_ = (t + g * key_aggCtx[2]) % secp256k1.CURVE.n

  return[Q.toRawBytes(), gacc_, tacc_];

}

export function key_agg_and_tweak(pubkeys, tweaks, is_xonly){
  let keyagg_ctx = key_agg(pubkeys);//key_aggCtx prior to tweaks

  if(tweaks.length != is_xonly.length) 
    {
      console.log("wrong length");
      return false;
    }  

  for(let i=0;i<tweaks.length;i++){
    keyagg_ctx=apply_tweak(keyagg_ctx, tweaks[i], is_xonly[i]);
   
  }
  return keyagg_ctx;
}

export function xbytes(bytes_Point){
  return bytes_Point.slice(1,33);
}

//input session context: 'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg
//return (Q, gacc, tacc, b, R, e)=[Point, int, int, int, Point, int]
export function get_session_values(SessionContext){

  let aggnonce=SessionContext[0];
  if(aggnonce.length!=66) return false;
  let keyagg_ctx=key_agg_and_tweak(SessionContext[1], SessionContext[2], SessionContext[3] );//Q, gacc, tacc
  

  let preconcat=Buffer.concat([xbytes(keyagg_ctx[0]), SessionContext[4]]);
  let concat=Buffer.concat([aggnonce, preconcat]);//aggnonce,Qx,msg

  let b = int_from_bytes(tagged_hashBTC('MuSig/noncecoef',concat)) % secp256k1.CURVE.n;
  let R1=ProjectivePoint.fromHex(aggnonce.slice(0,33));
  let R2=ProjectivePoint.fromHex(aggnonce.slice(33,66));

  let R=R1.add(R2.multiply(b));//R=R1+b.R2
  if(R.equals(secp256k1.ProjectivePoint.ZERO))
    R=secp256k1.ProjectivePoint.BASE;

  concat=Buffer.concat([xbytes(R.toRawBytes()), preconcat]);
  let e = int_from_bytes(tagged_hashBTC('BIP0340/challenge', concat)) % secp256k1.CURVE.n;

  return [keyagg_ctx[0], keyagg_ctx[1], keyagg_ctx[2], b, R.toRawBytes(), e];//(Q, gacc, tacc, b, R, e)
}

export function get_session_key_agg_coeff(pubkeys, pk){
  //todo: verify pk belongs to list
  return key_agg_coeff(pubkeys, pk);
}

/********************************************************************************************/
/* NONCE GENERATION FUNCTIONS*/   
/********************************************************************************************/

// RFC 6979 compliant nonce generation function
function rfc6979GenerateNonce(privateKey, message) {
  // Convert private key and message to bytes if necessary
 
  // Step 1: Hash the message using SHA-256
  const hash = sha256(message);

  // Step 2: Initialize V and K for HMAC-DRBG
  let v = new Uint8Array(32).fill(1);
  let k = new Uint8Array(32).fill(0);

  // Step 3: Update K and V using HMAC with privateKey + hash
  k = hmac(sha256, k, concatBytes(v, new Uint8Array([0]), privateKey, hash));
  v = hmac(sha256, k, v);

  // Step 4: Update K and V again using privateKey + hash
  k = hmac(sha256, k, concatBytes(v, new Uint8Array([1]), privateKey, hash));
  v = hmac(sha256, k, v);

  // Step 5: Generate candidate `k` until a valid one is found
  let candidateK;
  while (true) {
    v = hmac(sha256, k, v);
    candidateK = v;

    // Convert candidateK to a BigInt to check if it's valid
    const candidateKNum = BigInt('0x' + bytesToHex(candidateK));
    if (candidateKNum > 0n && candidateKNum < secp256k1.CURVE.n) {
      return candidateKNum;
    }

    // Update K and V with candidateK if invalid
    k = hmac(sha256, k, concatBytes(v, new Uint8Array([0])));
    v = hmac(sha256, k, v);
  }
}


//Hash to scalar for nonce
//all input are bytes
export function nonce_hash(rand, pk, aggpk, i, msgPrefixed, extraIn) {
  // Buffer to concatenate all inputs
  let buf =rand; 

  // Append all parts to the buffer
  
  buf = Buffer.concat([buf, new Uint8Array([pk.length])]); // Length of pk (1 byte)
  buf = Buffer.concat([buf, pk]);
  buf = Buffer.concat([buf, new Uint8Array([aggpk.length])]); // Length of aggpk (1 byte)
  buf = Buffer.concat([buf, aggpk]);
  buf = Buffer.concat([buf, msgPrefixed]);
  let extraInLengthBuffer = Buffer.alloc(4);
  extraInLengthBuffer.writeUInt32BE(extraIn.length);
  buf = Buffer.concat([buf, extraInLengthBuffer]); // Length of extraIn (4 bytes)
  buf = Buffer.concat([buf, extraIn]);
  buf = Buffer.concat([buf, new Uint8Array([i])]); // Index i (1 byte)

  // Compute the tagged hash with 'MuSig/nonce' as the tag
  const hash = tagged_hashBTC('MuSig/nonce', buf);

  // Return the result as a BigInt
  return hash;
}

//Let m_prefixed = bytes(1, 1) || bytes(8, len(m)) || m
export function prefix_msg(msg){

  if(msg.length==0) return Buffer.from("00",'hex');

  let buf=Buffer.from("01",'hex');
  let size = Buffer.alloc(8);
  size.writeBigUInt64BE(BigInt(msg.length));// Length of msg (8 bytes)

  buf = Buffer.concat([buf,size, msg]);

  return buf;
}

//expected format for sk is byte array
//aggpk is optional, compressed over 32 bytes
export function nonce_gen_internal(rand, sk,pk,aggpk, m,extra_in){
  if(sk.length!=0) {
    rand=bytes_xor(tagged_hashBTC('MuSig/aux', rand), sk)
  }

  let msg_prefixed=prefix_msg(m);

  let k_1 = nonce_hash(rand, pk, aggpk, 0, msg_prefixed, extra_in)
  let bk_1 = BigInt(`0x${k_1.toString('hex')}`)% secp256k1.CURVE.n;

  let k_2 = nonce_hash(rand, pk, aggpk, 1, msg_prefixed, extra_in) 
  let bk_2 = BigInt(`0x${k_2.toString('hex')}`)% secp256k1.CURVE.n;

  if(k_1==0) return false;
  if(k_2==0) return false;

  let P= secp256k1.ProjectivePoint.BASE;
  let Rs1 = (P.multiply(bk_1)).toRawBytes();
  let Rs2 = (P.multiply(bk_2)).toRawBytes();

  let pubnonce =  Buffer.concat([Rs1, Rs2]);
  let secnonce =  Buffer.concat([k_1, k_2, pk]);
  
  return [secnonce, pubnonce];
}

//individual nonce generation, use counter instead
export function nonce_gen(sk,pk,aggpk, m,extra_in){
  const rand =randomBytes(32);

  return nonce_gen_internal(rand, sk,pk,aggpk, m,extra_in);

}

//this part correspond to the round 1 of Musig: aggregation of individual nonces
//input is a 2 dimensional array of pubnonces of size u, in string format
export function nonce_agg(pubnonces){
 

  let u = pubnonces.length;
  let aggnonce = Buffer.alloc(0);
  for(let j=1;j<=2;j++){
    let Rj = secp256k1.ProjectivePoint.ZERO;//infinity neutral point
    
    for(let i=0;i<u;i++){
      
      let rij= pubnonces[i].slice((j - 1) * 66, j * 66);
      //hex to bytes, to cpoint
      let Rij=cpoint(Buffer.from(rij,'hex'));

      Rj= Rj.add(Rij);
    }
    aggnonce=Buffer.concat([aggnonce, cbytes_ext(Rj)]);
   

  }
  return aggnonce;
}



//todo: check that P1=P2 or P1==-P2 is true to avoid misuse of secnonce
export function equalsX(Point1, Point2){

  return true;
}
/********************************************************************************************/
/* MPC SIGNATURE GENERATION FUNCTIONS*/   
/********************************************************************************************/

//partial signature
//secnonce: 97 bytes
//sk: 32 bytes
//input session context: 'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg'
export function psign(secnonce, sk, session_ctx){
  
  let k1= int_from_bytes(secnonce.slice(0, 32));
  let k2= int_from_bytes(secnonce.slice(32, 64));

  let session_values= get_session_values(session_ctx);// (Q, gacc, _, b, R, e)  
  let Q=session_values[0];
  let gacc=session_values[1];
  let b=session_values[3];
  let R=session_values[4];
  let e=session_values[5];
  //todo : test range of k1 and k2
  if (has_even_y(R)==false)
    {
      k1=secp256k1.CURVE.n-k1;
      k2=secp256k1.CURVE.n-k2;
    }
  let d_ = int_from_bytes(sk)
  //todo : test range d

  let G= secp256k1.ProjectivePoint.BASE;
  let P = (G.multiply(d_));//should be equal to pk
  let secnonce_pk=secnonce.slice(64, 97);//pk is part of secnonce
  let Q3=ProjectivePoint.fromHex(secnonce_pk);

  //todo test x equality
  if(equalsX(P,Q3)==false){
    return false;//wrong public key
  }
  
  let a=get_session_key_agg_coeff(session_ctx[1], secnonce.slice(64, 97));

  let g=BigInt('0x1') ;
  if(has_even_y(Q)==false){//this line ensures the compatibility with requirement that aggregated key is even in verification
    g=secp256k1.CURVE.n-g;//n-1
    
  }
  let d = mulmod(g , gacc );//d = (g * gacc * d_) % n
  d= mulmod(d, d_);
  let s = (k1 + mulmod(b , k2) ) % secp256k1.CURVE.n;//
  s= (s+ mulmod(mulmod(e , a) , d))% secp256k1.CURVE.n;
 
  //todo: optional partial verif
  let psig=etc.numberToBytesBE(s,32);
 
  return psig;
}

//session context: 'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg

function mulmod(a, b) {
  return (a*b) % secp256k1.CURVE.n;
}


//operations are not constant time, not required as aggregation is a public function
export function partial_sig_agg(psigs, session_ctx){
  let sessionV=get_session_values(session_ctx);//(Q, gacc, tacc, b, R, e)
  let Q=sessionV[0];//aggnonce
  let tacc=sessionV[2];
  let b=sessionV[3];
  let e=sessionV[5];

  let s = BigInt(0);
  let u = psigs.length;
  for(let i=0;i<u;i++){
    let s_i = int_from_bytes(psigs[i])
    if(s_i>secp256k1.CURVE.n){
      return false;
    }
    s = (s + s_i) % secp256k1.CURVE.n;
  }
  let g=BigInt(1);
  if(has_even_y(Q)==false)
    g=secp256k1.CURVE.n - g;//n-1


  s = (s + e * g * tacc) % secp256k1.CURVE.n;
  s=Buffer.from(s.toString(16), 'hex');
  let R=xbytes(sessionV[4]);

  return Buffer.concat([R,s]);

}

//verify one of the partial signature provided by a participant
export function partial_sig_verify_internal(psig, pubnonce, pk, session_ctx){
  let sessionV=get_session_values(session_ctx);//(Q, gacc, tacc, b, R, e)
  let s = int_from_bytes(psig);
  let R_s1 = cpoint(pubnonce.slice(0,33));
  let R_s2 = cpoint(pubnonce.slice(33,66));

  let Re_s_ =R_s1.add(R_s2.multiply(b));
  let Re_s=Re_s_.toRawBytes();
  if(Re_s[0]=0x03){
    Re_s[0]=0x02;
  }
  Re_s=ProjectivePoint.fromHex(Re_s);
  a=key_agg_coeff(session_ctx[1], pk);
  let g=BigInt(1);
  if(has_even_y(Q)==false)
    g=secp256k1.CURVE.n - g;//n-1
  let P=ProjectivePoint.fromHex(pk);//partial input public key

  g=(g*gacc) % secp256k1.CURVE.n;
  
  let G= secp256k1.ProjectivePoint.BASE;
  let P1 = (G.multiply(s));
  let P2=Re_s.add(P.multiply((e*a*g)% secp256k1.CURVE.n));


  return (P1==P2);
}


/********************************************************************************************/
/* STANDARD SIGNATURE VERIFICATION FUNCTIONS*/   
/********************************************************************************************/

//this is schnorr BIP340, pubkey is x-coordinate only, assuming even y
export function schnorr_verify(msg, pubkey, sig){

  if(sig.length!=64) {
    console.log("bad sig length");
    return false;}

  if(pubkey.length!=32) {
  console.log("bad pubkey length"); 
    return false;
  }

  let r = int_from_bytes(sig.slice(0,32));
  let s = int_from_bytes(sig.slice(32,64));
  let RawP= Buffer.concat([ Buffer.from("02",'hex'), pubkey]);
  let P=secp256k1.ProjectivePoint.fromHex(RawP);//extract even public key of coordinates x=pubkey

  let concat=Buffer.concat([sig.slice(0,32),pubkey,msg]);
  let e = int_from_bytes(tagged_hashBTC('BIP0340/challenge', concat)) % secp256k1.CURVE.n;
  
  let sG=(secp256k1.ProjectivePoint.BASE).multiply(s);
  let meP=P.multiply( secp256k1.CURVE.n - e);

  let R =sG.add(meP).toRawBytes();//sG-eP, compressed
  if(has_even_y(R)!=true)
    return false;


  R=R.slice(1,33);//prune parity of y 

  if(int_from_bytes(R)!=r)
    return false;

  return true;
}

