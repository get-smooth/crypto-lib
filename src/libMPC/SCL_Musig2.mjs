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

import {  ed25519 } from '@noble/curves/ed25519';
import{reverse, bytes_xor, int_from_bytes, int_to_bytes, tagged_hashBTC, taghash_rfc8032} from "./common.mjs";

import { secp256k1 } from '@noble/curves/secp256k1';
import { etc, utils, getPublicKey } from '@noble/secp256k1';
import{SCL_ecc} from './SCL_ecc.mjs';
import { randomBytes } from 'crypto'; // Use Node.js's crypto module


/********************************************************************************************/
/* CLASS MUSIG2 */
/********************************************************************************************/
// Utility to handle different curves
export class SCL_Musig2 
{
    constructor(curve) {
      this.curve = new SCL_ecc(curve);

      if (this.curve.curve === 'secp256k1') {
        this.order=secp256k1.CURVE.n;
        this.RawBytesSize=33;//size of a compressed point with parity, 32bytes+1byte parity
      } else if (this.curve.curve === 'ed25519') {
        this.order=ed25519.CURVE.n;//size of a compressed point with parity, 32 bytes, including parity in msb bit.
        this.RawBytesSize=32;
      } else {
        throw new Error('Unsupported curve');
      }
    }

    //return bytes
    TagHash(tag, message){
        if (this.curve.curve === 'secp256k1') {
            return tagged_hashBTC(tag, message);
          } else if (this.curve.curve === 'ed25519') {
            return taghash_rfc8032(tag, message);
          } else {
            throw new Error('Unsupported curve');
          }
    }

    TagHashChallenge(tag,r,KpubC, Msg){
      if (this.curve.curve === 'secp256k1') {
        const encoded = Buffer.concat([r, KpubC, Msg]);
        return tagged_hashBTC(tag, encoded);
      } else if (this.curve.curve === 'ed25519') {   
        const encoded = Buffer.concat([reverse(r), reverse(KpubC), Msg]);
    
        return taghash_rfc8032('', encoded);
      } else {
        throw new Error('Unsupported curve');
      }

    }

    //hash the concatenation of public keys
    #Hash_keys(pubkeys){
    // Concatenate the list of public keys (byte arrays)
    const concatenatedPubkeys = Buffer.concat(pubkeys);
   
    // Use the tagged_hash function with the specified tag and concatenated public keys
    return this.TagHash('KeyAgg list', concatenatedPubkeys);
    }


    //return second public key, in order to implement Musig2* trick
    #Get_second_key(pubkeys){
        let u=pubkeys.length;
        for(let j =0; j<u;j++ )
          if(pubkeys[j] != pubkeys[0])
            return pubkeys[j];
          return 0;//there is no second Pubkey 
      }
    
      DerivKpub(sk){
        let Pub=this.GetBase().multiply(int_from_bytes(sk));
        return this.PointCompress(Pub); 
      }


/********************************************************************************************/
/* KEY AGGREGATION FUNCTIONS*/   
/********************************************************************************************/
  IndividualPubKey_array(scalar_array){
    if (this.curve.curve === 'secp256k1') {
      const publicKey = getPublicKey(scalar_array); 
      return publicKey;
    }
    if (this.curve.curve === 'ed25519') {
      const publicKey = this.curve.GetBase().multiply(int_from_bytes(scalar_array)); // 'true' for compressed format
      return this.curve.PointCompress(publicKey);//the getPublicKey is replaced by a scalar multiplication to be compatible with key aggregation
    }

    throw new Error('Unsupported curve');
  }

//return the ai coefficient 
    #Key_agg_coeff_internal(pubkeys, pki, pk2){
    let L = this.#Hash_keys(pubkeys);
   
    if (Buffer.from(pki).equals(pk2))
          {
            return BigInt('0x1');
          }
    return int_from_bytes(this.TagHash('KeyAgg coefficient', Buffer.concat([L , pki])))  % secp256k1.CURVE.n
  }


//return the ai coefficient using Musig2* trick 
    #Key_agg_coeff(pubkeys, pki){
    let pk2=this.#Get_second_key(pubkeys);
   
    return this.#Key_agg_coeff_internal(pubkeys, pki, pk2)
  }

  Key_agg(pubkeys){
    let pk2=this.#Get_second_key(pubkeys)
    let u=pubkeys.length;
    let Q = this.curve.GetZero();//infinity/neutral point
    let P= this.curve.GetBase();
    for(let i=0;i<u;i++){
      let Pi=this.curve.PointDecompress(pubkeys[i]);
     
      if(Pi==false)
        return false;
      let ai=this.#Key_agg_coeff_internal(pubkeys, pubkeys[i], pk2);
    
    
      Q = Q.add( Pi.multiply(ai));//Q=Q+aiPi  
     
    }
    if(Q==this.curve.GetZero())
      return false;
  
    return [this.curve.PointCompress(Q),BigInt(1),BigInt(0)]; //(Q,gacc,tacc), this is a key_aggCtx
  }
  
  prefix_msg(msg){

    if(msg.length==0) return Buffer.from("00",'hex');
  
    let buf=Buffer.from("01",'hex');
    let size = Buffer.alloc(8);
    size.writeBigUInt64BE(BigInt(msg.length));// Length of msg (8 bytes)
  
    buf = Buffer.concat([buf,size, msg]);
  
    return buf;
  }

/********************************************************************************************/
/* NONCE GENERATION FUNCTIONS*/   
/********************************************************************************************/

  Nonce_hash(rand, pk, aggpk, i, msgPrefixed, extraIn) {
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
    const hash = this.TagHash('MuSig/nonce', buf);
    // Return the result as a BigInt
    return hash;
  }


    //expected format for sk is byte array
    //aggpk is optional, compressed over 32 bytes
    Nonce_gen_internal(rand, sk,pk,aggpk, m,extra_in){
    if(sk.length!=0) {
      rand=bytes_xor(tagged_hashBTC('MuSig/aux', rand), sk)
    }
  
    let msg_prefixed=this.prefix_msg(m);
  
    let k_1 = this.Nonce_hash(rand, pk, aggpk, 0, msg_prefixed, extra_in)
    

    let bk_1 = int_from_bytes(k_1)% this.order;
  
    let k_2 = this.Nonce_hash(rand, pk, aggpk, 1, msg_prefixed, extra_in) 
    
    let bk_2 = int_from_bytes(k_2)% this.order;
  
    if(k_1==0) return false;
    if(k_2==0) return false;
  
    let P= this.curve.GetBase();
   
    let Rs1 = this.curve.PointCompress(P.multiply(bk_1));
    let Rs2 = this.curve.PointCompress(P.multiply(bk_2));

    let pubnonce =  Buffer.concat([Rs1, Rs2]);
    let secnonce =  Buffer.concat([k_1, k_2, pk]);
    
    return [secnonce, pubnonce];
  }

   Nonce_gen(sk,pk,aggpk, m,extra_in){
    const rand =randomBytes(32);//note that if sk is well protected, leakage of the nonce doesn't break the scheme
  
    return this.Nonce_gen_internal(rand, sk,pk,aggpk, m,extra_in);
  
   }
  
  //this part correspond to the round 1 of Musig: aggregation of individual nonces
  //input is a 2 dimensional array of pubnonces of size u, in string format
   Nonce_agg(pubnonces){
   
    let u = pubnonces.length;
    let aggnonce = Buffer.alloc(0);
    for(let j=1;j<=2;j++){
      let Rj = this.curve.GetZero();//infinity neutral point
      
      for(let i=0;i<u;i++){
       
        let rij= pubnonces[i].slice((j - 1) * (2*this.RawBytesSize), j * (2*this.RawBytesSize));
        //hex to bytes, to cpoint
        let Rij=this.curve.PointDecompress(Buffer.from(rij,'hex'));
  
        Rj= Rj.add(Rij);
      }
      aggnonce=Buffer.concat([aggnonce, this.curve.PointCompressExt(Rj)]);
     
  
    }
    return aggnonce;
  }

/********************************************************************************************/
/* TWEAKING FUNCTIONS*/   
/********************************************************************************************/
  //tweak is expected to be 32 bytes
  Apply_tweak(key_aggCtx, tweak, is_xonly){

    if(tweak.length!=32) return false;
    let t = int_from_bytes(tweak);
    if(t>this.order) return false;
    let Q=this.curve.PointDecompress(key_aggCtx[0]);
    let P= this.curve.GetBase();//base Point
    let g=BigInt('0x1') ;
  
  
    if(is_xonly&& (this.curve.Has_even_y(key_aggCtx[0])==false)){
      Q=Q.negate();
      g=order-g;//n-1
    }
  
    Q=Q.add(P.multiply(t));//Q=Q+t.P
    let gacc_ = (g * key_aggCtx[1] ) % this.order
    let tacc_ = (t + g * key_aggCtx[2]) % this.order
  
    return[this.curve.PointCompress(Q), gacc_, tacc_];
  
  }
  
  Key_agg_and_tweak(pubkeys, tweaks, is_xonly){
    let keyagg_ctx = this.Key_agg(pubkeys);//key_aggCtx prior to tweaks
  
    if(tweaks.length != is_xonly.length) 
      {
        console.log("wrong length");
        return false;
      }  
  
    for(let i=0;i<tweaks.length;i++){
      keyagg_ctx=this.Apply_tweak(keyagg_ctx, tweaks[i], is_xonly[i]);
     
    }
    return keyagg_ctx;
  }

//input session context: 'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg
//return (Q, gacc, tacc, b, R, e)=[Point, int, int, int, Point, int]
    Get_session_values(SessionContext){

    let aggnonce=SessionContext[0];
    if(aggnonce.length!=2*this.RawBytesSize) return false;
    let keyagg_ctx=this.Key_agg_and_tweak(SessionContext[1], SessionContext[2], SessionContext[3] );//Q, gacc, tacc
    
  
    let preconcat=Buffer.concat([this.curve.GetX(keyagg_ctx[0]), SessionContext[4]]);
    let concat=Buffer.concat([aggnonce, preconcat]);//aggnonce,Qx,msg
  
    let b = int_from_bytes(this.TagHash('MuSig/noncecoef',concat)) % this.order;
    let R1=this.curve.PointDecompress(aggnonce.slice(0,this.RawBytesSize));
    let R2=this.curve.PointDecompress(aggnonce.slice(this.RawBytesSize,(2*this.RawBytesSize)));
  
    let R=R1.add(R2.multiply(b));//R=R1+b.R2
    if(R.equals(this.curve.GetZero()))
      R=this.curve.GetBase();

    let RCompressed=this.curve.PointCompress(R);
    
    
    let e=this.TagHashChallenge('BIP0340/challenge', this.curve.GetX(RCompressed), this.curve.GetX(keyagg_ctx[0]), SessionContext[4])
    e=int_from_bytes(e) % this.order;
   

    return [keyagg_ctx[0], keyagg_ctx[1], keyagg_ctx[2], b, RCompressed, e];//(Q, gacc, tacc, b, R, e)
  }
  
    Get_session_key_agg_coeff(pubkeys, pk){
    //todo: verify pk belongs to list
    return this.#Key_agg_coeff(pubkeys, pk);
  }


/********************************************************************************************/
/* MPC SIGNATURE GENERATION FUNCTIONS*/   
/********************************************************************************************/
Mulmod(a,b){
    return (a*b)%this.order;
}

//operations are not constant time, not required as aggregation is a public function
Partial_sig_agg(psigs, session_ctx){
  let sessionV=this.Get_session_values(session_ctx);//(Q, gacc, tacc, b, R, e)
 

  let Q=sessionV[0];//aggnonce
  let tacc=sessionV[2];
 
  let e=sessionV[5];

  let s = BigInt(0);
  let u = psigs.length;
  for(let i=0;i<u;i++){
    let s_i = int_from_bytes(psigs[i])
    if(s_i> this.order){
      return false;
    }
    s = (s + s_i) % this.order;
  }
  let g=BigInt(1);
  if(this.curve.Has_even_y(Q)==false)
    g= this.order - g;//n-1


  s = (s + e * g * tacc) %  this.order;
  s=int_to_bytes(s,32);

  let R=this.curve.GetX(sessionV[4]);
  return Buffer.concat([R,s]);

}

//partial signature
//secnonce: 2 nonces + kpub
//sk: 32 bytes
//input session context: 'aggnonce','pubkeys', 'tweaks', 'is_xonly','msg'
Psign(secnonce, sk, session_ctx){
  
    let k1= int_from_bytes(secnonce.slice(0, 32));
    let k2= int_from_bytes(secnonce.slice(32, 64));
   
    let session_values= this.Get_session_values(session_ctx);// (Q, gacc, _, b, R, e)  
   

    let Q=session_values[0];
    let gacc=session_values[1];
    let b=session_values[3];
    let R=session_values[4];
    let e=session_values[5];
   

    //todo : test range of k1 and k2
    if (this.curve.Has_even_y(R)==false)
      {
        k1=this.order-k1;
        k2=this.order-k2;
      }
    let d_ = int_from_bytes(sk)
    //todo : test range d
  
    let G= this.curve.GetBase();
    let P = (G.multiply(d_));//should be equal to pk
    let secnonce_pk=secnonce.slice(64, 64+this.RawBytesSize);//pk is part of secnonce, 32 or 33 bytes
    let Q3=this.curve.PointDecompress(secnonce_pk);
  

    //todo test x equality
    if(this.curve.EqualsX(P,Q3)==false){
      return false;//wrong public key
    }
    
    let a=this.Get_session_key_agg_coeff(session_ctx[1], secnonce.slice(64, 64+this.RawBytesSize));
    

    let g=BigInt('0x1') ;
    if(this.curve.Has_even_y(Q)==false){//this line ensures the compatibility with requirement that aggregated key is even in verification
      g=this.order-g;//n-1
      
    }
    let d = this.Mulmod(g , gacc );//d = (g * gacc * d_) % n
    d= this.Mulmod(d, d_);//g*gacc*d
    let s = (k1 + this.Mulmod(b , k2) ) % this.order;//
    s= (s+ this.Mulmod(this.Mulmod(e , a) , d))% this.order;
   
    //todo: optional partial verif
    let psig=int_to_bytes(s,32);
   
    return psig;
  }


/********************************************************************************************/
/* VERIFICATIONS*/   
/********************************************************************************************/

//verify one of the partial signature provided by a participant
Psig_verify(psig, pubnonce, pk, session_ctx){
  let sessionV=this.Get_session_values(session_ctx);//(Q, gacc, _, b, R, e)
  let s = int_from_bytes(psig);
  let Q=sessionV[0];
  let gacc=sessionV[1];
  let b=sessionV[3];
  let R=sessionV[4];
  let e=sessionV[5];


  let R_s1 = this.curve.PointDecompress(pubnonce.slice(0,this.RawBytesSize));
  let R_s2 = this.curve.PointDecompress(pubnonce.slice(this.RawBytesSize,2*this.RawBytesSize));
 
  let Re_s_ =R_s1.add(R_s2.multiply(b));
  
  let Re_s=Re_s_;
  
  if(this.curve.Has_even_y(R)==false)
  {
     Re_s=Re_s.negate();//forced to even point
  }
  let P=this.curve.PointDecompress(pk);//partial input public key

  let a=this.Get_session_key_agg_coeff(session_ctx[1], pk);//session_ctx[1]=pubkeys
  

  let g=BigInt(1);
  if(this.curve.Has_even_y(Q)==false){
    g=this.order - g;//n-1
  }

  g=(g*gacc) % this.order;
  
  let G= this.curve.GetBase();
  let P1 = (G.multiply(s));

  let tmp=this.Mulmod(e,a);
  tmp=this.Mulmod(tmp,g);//e*a*g % n
  let P2=(Re_s.add(P.multiply(tmp)));

  return (P1.equals(P2));
}


//beware that this function take as input a msb representation of pubkey and signature
//key is assumed to be even
  Schnorr_verify(msg, pubkey, sig){

    if(sig.length!=64) {
      console.log("bad sig length");
      return false;}
  
    if(pubkey.length!=32) {
    console.log("bad pubkey length"); 
      return false;
    }
  
    let r = int_from_bytes(sig.slice(0,32));
    let s = int_from_bytes(sig.slice(32,64));
   
    let P=this.curve.PointDecompressEven(pubkey);//extract even public key of coordinates x=pubkey
   
    let e=int_from_bytes(this.TagHashChallenge('BIP0340/challenge', sig.slice(0,32), pubkey, msg)) % this.order
    let sG=(this.curve.GetBase()).multiply(s);
    let meP=P.multiply( this.order - e);//-eP
    let PointR=sG.add(meP);//sG-eP

    let R=this.curve.PointCompressXonly(PointR);
   
    if(int_from_bytes(R)!=r)
      return false;
  
    return true;
  }
}
/********************************************************************************************/
/* END OF CLASS MUSIG2 */
/********************************************************************************************/








