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
import{nonce_gen_internal, nonce_agg, key_agg, IndividualPubKey, psign, partial_sig_verify_internal} from './bip327.mjs'

import { utils, getPublicKey } from '@noble/secp256k1';

import{int_from_bytes, int_to_bytes} from "./common.mjs";

import{SCL_ecc} from './SCL_ecc.mjs';
import{SCL_Musig2} from './SCL_Musig2.mjs';

import { randomBytes } from 'crypto'; // Use Node.js's crypto module



/********************************************************************************************/
/* ATOMIC SWAP PRIMITIVES */   
/********************************************************************************************/

//the Alice adaptator signature
//sk_A is Alice secret Key
//rA is the secnonce
//R is the public agg nonce
//Pub_AB is the Musig2 agreed multisig key between Alice and Bob
//Pub_A is Alice public key

export function psign_adapt(psig, t){

  sprime=(int_from_bytes(psig)+int_from_bytes(t)) % secp256k1.CURVE.n;

  return sprime;
}

//check that a tweaked partially signature is valid
export function partial_adaptatorsig_verify_internal(psig, pubnonce, pk, session_ctx, T){

 return true;
}

export function atomic_check(tG, psA1, psA2, psB1, psB2, QA, R, msg1, msg2){

 return true;
}


export function get_tweak_from_sigs(sAp, sB, sAB)
{
  const sABp=partial_sig_agg([sAp, sB]);
  t=(sABp-sAB)% secp256k1.CURVE.n;
  return t;
}

//the function takes as input an adaptator signature, its tweak t, and a valid signature, and returns the Musig2 corresponding signature
export function sign_untweak(t, psigA_adapt, psigB){
  const sABp=partial_sig_agg([psigA_adapt, psigB]);

  const sAB= (sABp - t)% secp256k1.CURVE.n;

  return sAB;
}

export function atomic_example(){

  // Alice and Bob private keys
  const skA = utils.randomPrivateKey();
  console.log("sk", skA);
  const skB = utils.randomPrivateKey();
  
  //Alice and Bob public keys
  const QA= IndividualPubKey(skA); 
  const QB= IndividualPubKey(skB);

  const pubkeys=[QA, QB];
  
  const msg1=Buffer.from("Unlock 1strkBTC on Starknet to Alice",'utf-8');
  console.log("msg1=",msg1);
  const msg2=Buffer.from("Unlock 1WBTC on Ethereum to Bob",'utf-8');
  
  
  //key aggregation
  const QAB=key_agg([QA, QB])[0];
  console.log("QAB=",QAB);

  //nonce generation

  const nonceA1=nonce_gen_internal(utils.randomPrivateKey(), skA, QA, QAB, msg1, Buffer.from(""));//alice generates its nonce
  const nonceA2=nonce_gen_internal(utils.randomPrivateKey(), skA, QA, QAB, msg2, Buffer.from(""));//alice generates its nonce

  const nonceB1=nonce_gen_internal(utils.randomPrivateKey(), skB, QB, QAB, msg1, Buffer.from(""));//alice generates its nonce
  const nonceB2=nonce_gen_internal(utils.randomPrivateKey(), skB, QB, QAB, msg2, Buffer.from(""));//alice generates its nonce
  

  //alice and Bob construct common nonce from pubnonces
  const R1=nonce_agg([nonceA1[1], nonceB1[1]]);
  const R2=nonce_agg([nonceA2[1], nonceB2[1]]);
  
  session_ctx1=[R1, pubkeys, [], [], msg1];
  session_ctx2=[R1, pubkeys, [], [], msg2];
  

  //Alice locks one BTC on Ethereum, using the corresponding Musig2 adress, it is unlocked with msg2 multisig or timelock expiration
  //bob locks one BTC on starknet, using the corresponding Musig2 adress, it is unlocked with msg1 multisig or timelock expiration

  //alice generates a secret adaptator tweak and publish offchain the value tG
  const t = utils.randomPrivateKey();

  //alice generates the secret adaptator signatures sA'1 and sA'2 for both message and broadcast them offchain
  const psigA1=psign(nonceA1[0], skA, session_ctx1)
  const sAp1=psign_adapt(psigA1, t);
  const psigA2=psign(nonceA2[0], skA, session_ctx1)
  const sAp2=psign_adapt(psigA2, t);

  //bob check the compliance, then broadcast offchain signature of message 1 sb1
  psigB1=psign(nonceB1, skB, session_ctx1);
  
  //Alice unlocks its strkBTC, using sb1, thus revealing the tweak to Bob
  sAB1=partial_sig_agg([psigA1, psigB1], session_ctx1);

  //Bob reads onchain 1 the value of t, then compute the value of SAB2, unlocking its token
  const rec_t=get_tweak_from_sigs(sAB1, sAp1, psigB1);
  const sAB2=sign_untweak( psigA2);
  
}

function  Psign_adapt(curve, psig, t){

    let sprime=(int_from_bytes(psig)+t ) % curve.order;
    
    return sprime;
  }

function  Untweak(t, psigA_adapt, psigB){
    const sABp=partial_sig_agg([psigA_adapt, psigB]);
  
    const sAB= (sABp - t)% secp256k1.CURVE.n;
  
    return sAB;
  }


//verify one of the partial signature provided by a participant
function Psig_verifyTweaked(signer, psig, pubnonce, pk, session_ctx, tG){
  let sessionV=signer.Get_session_values(session_ctx);//(Q, gacc, _, b, R, e)
  let s = int_from_bytes(psig);
  let Q=sessionV[0];
  let gacc=sessionV[1];
  let b=sessionV[3];
  let R=sessionV[4];
  let e=sessionV[5];


  let R_s1 = signer.curve.PointDecompress(pubnonce.slice(0,signer.RawBytesSize));
  let R_s2 = signer.curve.PointDecompress(pubnonce.slice(signer.RawBytesSize,2*signer.RawBytesSize));
 
  let Re_s_ =R_s1.add(R_s2.multiply(b));
  
  let Re_s=Re_s_;
  
  if(signer.curve.Has_even_y(R)==false)
  {
     Re_s=Re_s.negate();//forced to even point
  }
  let P=signer.curve.PointDecompress(pk);//partial input public key

  let a=signer.Get_session_key_agg_coeff(session_ctx[1], pk);//session_ctx[1]=pubkeys
  

  let g=BigInt(1);
  if(signer.curve.Has_even_y(Q)==false){
    g=signer.order - g;//n-1
  }

  g=(g*gacc) % signer.order;
  
  let G= signer.curve.GetBase();
  let P1 = (G.multiply(s));

  let tmp=signer.Mulmod(e,a);
  tmp=signer.Mulmod(tmp,g);//e*a*g % n
  let P2=(Re_s.add(P.multiply(tmp)));
  P2=P2.add(tG);

  return (P1.equals(P2));
}

/********************************************************************************************/
/* INITIATOR AUTOMATA*/   
/********************************************************************************************/
export class SCL_Atomic_Initiator{

  constructor(curve,  sk) {

    this.signer=new SCL_Musig2(curve);
    this.sk=sk;

    this.pubkey=this.signer.IndividualPubKey_array(sk);


    this.state="idle";

    this.nonceA1=0;
    this.nonceA2=0;
    
    this.pubKeyDist=0;//the responder distant public key
    this.nonceB1=0;
    this.nonceB2=0;
    
    this.t=0;

    this.tx1=0;
    this.tx2=0;
    this.tG=0;
  }

  ResetSession(){
    this.state="idle";

    this.nonceA1=0;
    this.nonceA2=0;
    
    this.nonceB1=0;
    this.nonceB2=0;
    
  }

  InitSession(tx1, tx2,pubKeyDist)
  {

    this.pubKeyDist=pubKeyDist;
    console.log("input: ", this.pubkey, this.pubKeyDist);

    this.aggpk = this.signer.Key_agg([this.pubkey, this.pubKeyDist])[0];

    let x_aggpk=this.signer.curve.ForceXonly(this.aggpk);//x-only version for noncegen, allways 32

    //anti replay through nonces
    let extra_in1=this.signer.curve.Get_Random_privateKey();
    let extra_in2=this.signer.curve.Get_Random_privateKey();
    

    this.nonceA1= this.signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  tx1, extra_in1);
    this.nonceA2= this.signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  tx2, extra_in2);
    this.tx1=tx1;
    this.tx2=tx2;
    
    let Message_I1=[tx1, tx2, this.nonceA1[1], this.nonceA2[1], this.pubkey];

    this.state="waitR1"
    return Message_I1;//this message is broadcast offchain
  }

  //Message_R1=[aggnonce1, aggnonce2, nonceB1[1], nonceB2[1]];
  PartialSign_Tweaked(Message_R1){
    let Message_I2=[];

    this.nonceB1=Message_R1[2];
    this.nonceB2=Message_R1[3];
   
    let aggnonce1 = this.signer.Nonce_agg([this.nonceA1[1].toString('hex'), this.nonceB1.toString('hex')]);
    let aggnonce2 = this.signer.Nonce_agg([this.nonceA2[1].toString('hex'), this.nonceB2.toString('hex')]);
    
    const session_ctx1=[aggnonce1, [this.pubkey, this.pubKeyDist], [], [], this.tx1];//session_ctx=[aggnonce, pubkeys, [], [], msg];
    const session_ctx2=[aggnonce2, [this.pubkey, this.pubKeyDist], [], [], this.tx2];


    let psigI1=this.signer.Psign(this.nonceA1[0], this.sk, session_ctx1);
    console.log("Partial verify:", this.signer.Psig_verify(psigI1, this.nonceA1[1], this.pubkey, session_ctx1));
    let psigI2=this.signer.Psign(this.nonceA2[0], this.sk, session_ctx2);
    

    this.t=int_from_bytes(this.signer.curve.Get_Random_privateKey());
    let G= this.signer.curve.GetBase();
    this.tG=G.multiply(this.t);


    let psigI1p=Psign_adapt(this.signer.curve, psigI1,this.t)
    let psigI2p=Psign_adapt(this.signer.curve, psigI2,this.t)

    Message_I2=[psigI1p, psigI2p, this.tG];
    let checkpoint=Psig_verifyTweaked(this.signer, int_to_bytes(psigI1p,32), this.nonceA1[1], this.pubkey, session_ctx1, this.tG);
    console.log("verify tweaked:", checkpoint);
    checkpoint=Psig_verifyTweaked(this.signer, int_to_bytes(psigI2p,32), this.nonceA2[1], this.pubkey, session_ctx2, this.tG);
    console.log("verify tweaked:", checkpoint);

    this.state="waitR2"
    return Message_I2;//this message is broadcast offchain
  }

  //here it is assumed that Initiator checked that deposit has been made and locked by signature of tx1 on Chain1
  FinalUnlock(Message_R2){
    let Message_I3=[];


    this.state="idle";
    return Message_I3;//this message is broadcast onchain to unlock initiator exit liquidity

  }


}

/********************************************************************************************/
/* RESPONDER AUTOMATA*/   
/********************************************************************************************/
export class SCL_Atomic_Responder{
  
  constructor(curve, sk) {

    this.signer=new SCL_Musig2(curve);
   
    this.sk=sk; 
    this.pubkey=this.signer.IndividualPubKey_array(sk);

    this.state="idle";

    this.pubKeyDist=0;//the initiator distant public key
    this.aggpk = 0;
    this.nonceA1=0;
    this.nonceA2=0;
    
    this.nonceB1=0;
    this.nonceB2=0;

    this.tx1=0;
    this.tx2=0;
  }


  ResetSession(){
    this.state="idle";

    this.nonceA1=0;
    this.nonceA2=0;
    
    this.nonceB1=0;
    this.nonceB2=0;
    
  }

  RespondInit(Message_I1 )
  {
    this.tx1=Message_I1[0];
    this.tx2=Message_I1[1];    
    this.nonceA1= Message_I1[2];
    this.nonceA2= Message_I1[3];
    this.pubKeyDist=Message_I1[4];

    this.aggpk = this.signer.Key_agg([this.pubKeyDist, this.pubkey])[0];
    let x_aggpk=this.signer.curve.ForceXonly(this.aggpk);//x-only version for noncegen, allways 32
    //anti replay through nonces
    let extra_in1=this.signer.curve.Get_Random_privateKey();
    let extra_in2=this.signer.curve.Get_Random_privateKey();
 
    let nonceB1= this.signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  this.tx1, extra_in1);
    let nonceB2= this.signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  this.tx2, extra_in2);

    let aggnonce1 = this.signer.Nonce_agg([this.nonceA1.toString('hex'), nonceB1[1].toString('hex')]);
    let aggnonce2 = this.signer.Nonce_agg([this.nonceA2.toString('hex'), nonceB2[1].toString('hex')]);
    
    let Message_R1=[aggnonce1, aggnonce2, nonceB1[1], nonceB2[1]];

    this.state="waitI2";

    return Message_R1;//this message is broadcast offchain
  }

  PartialSign(Message_I2){
    let Message_R2=[];

    //Prior to release PsigB, check compliance of transmitted elements

    //Compute partial sig
    let psigI1=signer.Psign(nonceB1[0], this.sk, session_ctx1);
    let psigI2=signer.Psign(nonceB2[0], this.sk, session_ctx2);
    


    this.state="waitI3";
    return Message_R2;//this message is broadcast onchain to unlock responder exit liquidity

  }

  FinalUnlock(Message_I3){
    let Message_R3=[];

    this.state="idle";
    return Message_R3;//this message is broadcast onchain to unlock responder exit liquidity

  }

}

