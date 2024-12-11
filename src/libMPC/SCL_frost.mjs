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
import { Field } from "@noble/curves/abstract/modular";



//beware that because horner method is used degree 0 coefficient is last of the list
function Evaluate(coeffs,x, modulus){
    let res=coeffs[0];//a0
    for(let i=1;i<coeffs.length;i++){
        res=((res*x)+(coeffs[i]))%modulus;
    }
    return res;
}

//Lagrangian interpolation in 0= prod(x_i)/prod(xj-xi)
function Interpolate(L, x_i, modulus){
        let num=BigInt(1);
        let deno=BigInt(1);

    for(let j=0;j<L.length;j++)
    {
        let x_j=L[j]
        if( x_j != x_i){
            num=(num*x_j)%modulus;
            deno=deno*(modulus+x_j-x_i)%modulus;

        }
    }
    let F=Field(BigInt(modulus));
    return (num * F.pow(deno, modulus - BigInt(2))) % modulus;
    }

//interpolate the points (xi,P(xi).G) in 0 (group public key)
//pubkeys is a list of point
//ids is a list of bigInt
export function Interpolate_group_pubkey(pubkeys, ids, curve){
  let Q = curve.GetZero();
  if(pubkeys.length!=ids.length){
      return false;
  }
  for(let i=0;i<pubkeys.length;i++){
      //console.log("Pi", pubkeys[i])
      //console.log("id", ids[i])
      
      let Xi=pubkeys[i];
     // console.log("Xi", Xi);
      let lam_i = Interpolate(ids, ids[i], curve.order);
     // console.log("lam_i", lam_i);
     // console.log("lam_i.Xi", Xi.multiply(lam_i));
      
      Q=Q.add(Xi.multiply(lam_i));

     // console.log("trace Q:", Q)
  }
  //todo: test infty
  return curve.PointCompress(Q);
}


//interpolate the points (xi,P(xi).G) in 0 (group public key)
//pubkeys is a list of bytes 
//ids is a list of bigInt
export function Interpolate_group_BytesPubkey(pubkeys, ids, curve){
    let Q = curve.GetZero();
    if(pubkeys.length!=ids.length){
        return false;
    }
    for(let i=0;i<pubkeys.length;i++){
        //console.log("Pi", pubkeys[i])
        //console.log("id", ids[i])
        
        let Xi=curve.PointDecompress(pubkeys[i]);
       // console.log("Xi", Xi);
        let lam_i = Interpolate(ids, ids[i], curve.order);
       // console.log("lam_i", lam_i);
       // console.log("lam_i.Xi", Xi.multiply(lam_i));
        
        Q=Q.add(Xi.multiply(lam_i));
  
       // console.log("trace Q:", Q)
    }
    //todo: test infty
    return curve.PointCompress(Q);
  }

  
export class SCL_trustedKeyGen
{
    constructor(curve,  sk, n, k) {

        this.curve=new SCL_ecc(curve);
        this.sk=sk;
    
        this.pubkey=this.curve.IndividualPubKey_array(sk);
    
        this.n=n;
        this.degree=k;
        this.min_participants=k+1;
        this.pubshares=[];
        this.secshares=[];
        this.coeffs=[];
       
        this.KeyGen(n, k+1);
        this.ids=this.secshares.map(points =>points[0]);
        
      }

      //in the future, improve it with a PRNG using secret and random generator
      GetRandomElement(){
        return this.curve.Get_Random_privateKey();
      }

      KeyGen(n, min_participants){

        if(min_participants<1) return false;

        this.n=n;//maximum number of participants
        this.degree=min_participants-1;//minimum number of participants = degree of polynomial-1


        //generate secret polynomial: 
        for(let i=this.degree;i>0;i--){
            let ai=this.GetRandomElement();
            this.coeffs.push(int_from_bytes(ai));
        }
        this.coeffs.push(int_from_bytes(this.sk));//a0=P(0)=secret
        
       
        //Shares are evaluation of P starting from 1, P(0) being the secret
        for(let xi=1;xi<this.n+1;xi++){

            let yi=Evaluate(this.coeffs, BigInt(xi), this.curve.order);
            this.secshares.push([BigInt(xi),yi]);
            this.pubshares.push(this.curve.GetBase().multiply(BigInt(yi)));
      
        }

      }

      //interpolate the points (xi,P(xi)) in 0 (group secret key)
      Interpolate_group_seckey( points ){

        let P0=BigInt(0);
        for(let i=0;i<points.length;i++){
            let x=points[i][0];
            let delta=points[i][1] * Interpolate(points.map(points =>points[0]),x, this.curve.order);//yi * interpolate(L,xi)
            P0=(P0 + delta)%this.curve.order;
        }
        return P0;
      }



      Check_Shares()
      {
        if (this.n<this.min_participants)
            return false;
        //check secshares.G=pubshares
        //console.log(this.secshares);

        for(let i=0;i<this.n;i++){
            let recPub=this.curve.GetBase().multiply(this.secshares[i][1]);
            if(recPub.equals(this.pubshares[i])==false)
                return false;
        }

        return true;
      }



}


export class SCL_FROST{

    constructor(curve) {

        this.curve=new SCL_ecc(curve);

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
/********************************************************************************************/
/* NONCE GENERATION FUNCTIONS*/   
/********************************************************************************************/

prefix_msg(msg){

    if(msg.length==0) return Buffer.from("00",'hex');
  
    let buf=Buffer.from("01",'hex');
    let size = Buffer.alloc(8);
    size.writeBigUInt64BE(BigInt(msg.length));// Length of msg (8 bytes)
  
    buf = Buffer.concat([buf,size, msg]);
  
    return buf;
  }

//identical to Musig2, except hash domain separation
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
    const hash = this.TagHash('FROST/nonce', buf);
    // Return the result as a BigInt
    return hash;
  }
  

    //expected format for sk is byte array
    //aggpk is optional, compressed over 32 bytes
    Nonce_gen_internal(rand, sk,pk,aggpk, m,extra_in){
        if(sk.length!=0) {
          rand=bytes_xor(tagged_hashBTC('FROST/aux', rand), sk)
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


      Nonce_gen(sk,pk,group_pk, m,extra_in){
        const rand =randomBytes(32);//note that if sk is well protected, leakage of the nonce doesn't break the scheme

        return this.Nonce_gen_internal(rand, sk,pk,group_pk, m,extra_in);
      
       }

  //this part correspond to the round 1 of Musig: aggregation of individual nonces
  //input
  //pubnonces is a 2 dimensional array of pubnonces of size u, in string format
  //ids is a list of BigInt
  //it is assumed that the pubkey of aggregator is not part of pubnonces
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

  //compared to Musig2, a session context only requires the ids (point to interpolate)
  //input session context: 'aggnonce', ids, 'pubkeys', 'tweaks', 'is_xonly','msg'

/********************************************************************************************/
/* TWEAKING FUNCTIONS*/   
/********************************************************************************************/
  //tweak is expected to be 32 bytes. This function is strictly identical to Musig2 tweaking
   Apply_tweak(tweak_ctx, tweak, is_xonly){

    if(tweak.length!=32) return false;
    let t = int_from_bytes(tweak);
    if(t>this.order) return false;
    let Q=this.curve.PointDecompress(key_aggCtx[0]);
    let P= this.curve.GetBase();//base Point
    let g=BigInt('0x1') ;
  
  
    if(is_xonly&& (this.curve.Has_even_y(tweak_ctx[0])==false)){
      Q=Q.negate();
      g=order-g;//n-1
    }
  
    Q=Q.add(P.multiply(t));//Q=Q+t.P
    let gacc_ = (g * tweak_ctx[1] ) % this.curve.order
    let tacc_ = (t + g * tweak_ctx[2]) % this.curve.order
  
    return[this.curve.PointCompress(Q), gacc_, tacc_];
  }

 //pubkeys as list of points here
 Group_pubkey_and_tweak(pubkeys, ids, tweaks, is_xonly){
    if(pubkeys.length!=ids.length){
        return false;
    }
    let Q=Interpolate_group_BytesPubkey(pubkeys, ids, this.curve);
    let gacc=BigInt(1);
    let tacc=BigInt(0);

    let tweak_ctx=[Q, gacc, tacc];

    for(let i=0;i<tweaks.length;i++){
        tweak_ctx=this.Apply_tweak(tweak_ctx, tweaks[i], is_xonly[i])

    }

    return tweak_ctx;
 }

 //ids are assumed to be sorted
 #ConcatIds(ids){
    let concat=int_to_bytes(ids[0],32);
    for(let i=1;i<ids.length;i++){
        if(ids[i]<ids[i-1]){
            throw new Error('ids are not sorted ');
        }
        concat=Buffer.concat([concat, int_to_bytes(ids[i], 32)])//well, we shall not see more than 4B distincts signers
    }

    return concat;
 }
 
//input session context: 'aggnonce','ids', 'pubkeys', 'tweaks', 'is_xonly','msg
//return (Q, gacc, tacc, b, R, e)=[Point, int, int, int, Point, int]
//ids are supposed to be sorted here
Get_session_values(SessionContext){

    let aggnonce=SessionContext[0];
    if(aggnonce.length!=2*this.RawBytesSize) return false;
    
    let concat_ids=this.#ConcatIds(SessionContext[1])//concatenation of identifiers

    let tweak_ctx=this.Group_pubkey_and_tweak(SessionContext[2], SessionContext[1], SessionContext[3], SessionContext[4] );//Q, gacc, tacc
   
    let preconcat=Buffer.concat([this.curve.GetX(tweak_ctx[0]), SessionContext[5]]);//Qx,msg
    let concat=Buffer.concat([concat_ids, aggnonce, preconcat]);//ids, aggnonce,Qx,msg
  
    let b = int_from_bytes(this.TagHash('FROST/noncecoef',concat)) % this.order;
    let R1=this.curve.PointDecompress(aggnonce.slice(0,this.RawBytesSize));
    let R2=this.curve.PointDecompress(aggnonce.slice(this.RawBytesSize,(2*this.RawBytesSize)));
  
    let R=R1.add(R2.multiply(b));//R=R1+b.R2
    if(R.equals(this.curve.GetZero()))
      R=this.curve.GetBase();

    let RCompressed=this.curve.PointCompress(R);
    
    
    let e=this.TagHashChallenge('BIP0340/challenge', this.curve.GetX(RCompressed), this.curve.GetX(tweak_ctx[0]), SessionContext[5])
    e=int_from_bytes(e) % this.order;
   

    return [tweak_ctx[0], tweak_ctx[1], tweak_ctx[2], b, RCompressed, e];//(Q, gacc, tacc, b, R, e)
  }
  

/********************************************************************************************/
/* SIGNATURE FUNCTIONS*/   
/********************************************************************************************/

Mulmod(a,b){
    return (a*b)%this.order;
}

//partial signature
//secnonce: 2 nonces + kpub
//sk: 32 bytes
//input session context: 'aggnonce', 'ids', 'pubkeys', 'tweaks', 'is_xonly','msg'
Psign(secnonce, secshare, id, session_ctx){


    if(id>this.curve.order)
        {
            return false;
        }

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
    let d_ = int_from_bytes(secshare)
    //todo : test range d
  
    let G= this.curve.GetBase();
    let P = (G.multiply(d_));//should be equal to pk
    
    let a=Interpolate(session_ctx[1], id, this.curve.order);
    
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


//operations are not constant time, not required as aggregation is a public function
//input session context: 'aggnonce', 'ids', 'pubkeys', 'tweaks', 'is_xonly','msg'
Partial_sig_agg(psigs, ids, session_ctx){
    let sessionV=this.Get_session_values(session_ctx);//(Q, gacc, tacc, b, R, e)
   
    if(psigs.length!=ids.length){
        return false;
    }

    let Q=sessionV[0];//aggnonce
    let tacc=sessionV[2];
   
    let e=sessionV[5];
  
    let s = BigInt(0);
    let u = psigs.length;
    for(let i=0;i<u;i++){
      let s_i = int_from_bytes(psigs[i])
      if(s_i> this.order){
        throw new Error('Invalid contribution for id:', ids[i]);
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
  
/********************************************************************************************/
/* VERIFICATIONS*/   
/********************************************************************************************/

//verify one of the partial signature provided by a participant
Psig_verify(psig, id, pubnonce, pk, session_ctx){


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
  
    let a=this.Interpolate(session_ctx[1], id);//session_ctx[1]=ids
    
  
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