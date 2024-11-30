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


function get_tweak_from_sigs(sAp, sB, sAB)
{
  const sABp=partial_sig_agg([sAp, sB]);
  t=(sABp-sAB)% secp256k1.CURVE.n;
  return t;
}

//the function takes as input an adaptator signature, its tweak t, and a valid signature, and returns the Musig2 corresponding signature
function sign_untweak(t, psigA_adapt, psigB){
  const sABp=partial_sig_agg([psigA_adapt, psigB]);

  const sAB= (sABp - t)% secp256k1.CURVE.n;

  return sAB;
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

    this.ResetSession();
   
  }

  ResetSession(){
    this.state="idle";

    this.nonceA1=0;
    this.nonceA2=0;

    this.aggnonce1=0;
    this.aggnonce2=0;
    
    this.pubKeyDist=0;//the responder distant public key
    this.nonceB1=0;
    this.nonceB2=0;
    
    this.t=0;

    this.tx1=0;
    this.tx2=0;
    this.tG=0;
  }

  InitSession(tx1, tx2,pubKeyDist)
  {

    this.pubKeyDist=pubKeyDist;
   
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
   
    this.aggnonce1 = this.signer.Nonce_agg([this.nonceA1[1].toString('hex'), this.nonceB1.toString('hex')]);
    this.aggnonce2 = this.signer.Nonce_agg([this.nonceA2[1].toString('hex'), this.nonceB2.toString('hex')]);
    

    const session_ctx1=[this.aggnonce1, [this.pubkey, this.pubKeyDist], [], [], this.tx1];//session_ctx=[aggnonce, pubkeys, [], [], msg];
    const session_ctx2=[this.aggnonce2, [this.pubkey, this.pubKeyDist], [], [], this.tx2];


    let psigI1=this.signer.Psign(this.nonceA1[0], this.sk, session_ctx1);
    console.log("Partial verify:", this.signer.Psig_verify(psigI1, this.nonceA1[1], this.pubkey, session_ctx1));
    let psigI2=this.signer.Psign(this.nonceA2[0], this.sk, session_ctx2);
    

    this.t=int_from_bytes(this.signer.curve.Get_Random_privateKey());
    
    let G= this.signer.curve.GetBase();
    this.tG=G.multiply(this.t);


    let psigI1p=Psign_adapt(this.signer.curve, psigI1,this.t)
    let psigI2p=Psign_adapt(this.signer.curve, psigI2,this.t)

    
    //console.log("session ctx view from i:", session_ctx1);
    let checkpoint=Psig_verifyTweaked(this.signer, int_to_bytes(psigI1p,32), this.nonceA1[1], this.pubkey, session_ctx1, this.tG);
    console.log("verify tweaked:", checkpoint);
    checkpoint=Psig_verifyTweaked(this.signer, int_to_bytes(psigI2p,32), this.nonceA2[1], this.pubkey, session_ctx2, this.tG);
    console.log("verify tweaked:", checkpoint);

    Message_I2=[psigI1p, psigI2p, this.tG];
    this.state="waitR2"
    return Message_I2;//this message is broadcast offchain
  }

  //here it is assumed that Initiator checked that deposit has been made and locked by signature of tx1 on Chain1
  FinalUnlock(Message_R2){
    let psigR1=Message_R2[0];
    let psigR2=Message_R2[1];
    let x_aggpk=this.signer.curve.ForceXonly(this.aggpk);//x-only version for noncegen, allways 32


    let Message_I3=[];


    //Alice check correctness of partial sig from Bob
    const session_ctx1=[this.aggnonce1, [this.pubkey, this.pubKeyDist], [], [], this.tx1];//session_ctx=[aggnonce, pubkeys, [], [], msg];
    console.log("Partial verify:", this.signer.Psig_verify(psigR1, this.nonceB1, this.pubKeyDist, session_ctx1));
    const session_ctx2=[this.aggnonce2, [this.pubkey, this.pubKeyDist], [], [], this.tx2];//session_ctx=[aggnonce, pubkeys, [], [], msg];
    console.log("Partial verify:", this.signer.Psig_verify(psigR2, this.nonceB2, this.pubKeyDist, session_ctx2));
    
    let psigI1=this.signer.Psign(this.nonceA1[0], this.sk, session_ctx1);
    let SIG_ABTX1=this.signer.Partial_sig_agg([psigI1, psigR1], session_ctx1);

    let psigI2=this.signer.Psign(this.nonceA2[0], this.sk, session_ctx2);
    let SIG_ABTX2=this.signer.Partial_sig_agg([psigI2, psigR2], session_ctx2);

    //check final result is legit
    let check1=this.signer.Schnorr_verify(this.tx1, x_aggpk, SIG_ABTX1);
    let check2=this.signer.Schnorr_verify(this.tx2, x_aggpk, SIG_ABTX2);

    console.log("final check:", check1, check2);
    this.ResetSession();
    return [SIG_ABTX1, SIG_ABTX2];//this message is broadcast onchain to unlock initiator exit liquidity

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
    this.ResetSession();
  }


  ResetSession(){
   
    this.state="idle";

    this.pubKeyDist=0;//the initiator distant public key
    this.aggpk = 0;
    this.nonceA1=0;
    this.nonceA2=0;
    
    this.nonceB1=0;
    this.nonceB2=0;
    this.aggnonce1=0;
    this.aggnonce2=0;
    this.tG=0;

    this.SIG_ABTX1p=0;
    this.SIG_ABTX2p=0;
    this.psigI2p=0;
    this.psigR2=0;

    this.tx1=0;
    this.tx2=0;
    
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
 
    this.nonceB1= this.signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  this.tx1, extra_in1);
    this.nonceB2= this.signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  this.tx2, extra_in2);

    this.aggnonce1 = this.signer.Nonce_agg([this.nonceA1.toString('hex'), this.nonceB1[1].toString('hex')]);
    this.aggnonce2 = this.signer.Nonce_agg([this.nonceA2.toString('hex'), this.nonceB2[1].toString('hex')]);
    

    let Message_R1=[this.aggnonce1, this.aggnonce2, this.nonceB1[1], this.nonceB2[1]];

    this.state="waitI2";

    return Message_R1;//this message is broadcast offchain
  }

  //Message_I2=[psigI1p, psigI2p, this.tG];
  PartialSign(Message_I2){
    let Message_R2=[];
    this.tG=Message_I2[2];

    let psigI1p=Message_I2[0];
    let psigI2p=Message_I2[1];

    //Prior to release PsigB, check compliance of transmitted elements
    const session_ctx1=[this.aggnonce1, [ this.pubKeyDist, this.pubkey], [], [], this.tx1];//session_ctx=[aggnonce, pubkeys, [], [], msg];
    const session_ctx2=[this.aggnonce2, [ this.pubKeyDist, this.pubkey], [], [], this.tx2];//session_ctx=[aggnonce, pubkeys, [], [], msg];
   
    let checkpoint1=Psig_verifyTweaked(this.signer, int_to_bytes(psigI1p,32), this.nonceA1, this.pubKeyDist, session_ctx1, this.tG);
    if(checkpoint1==false){
      return false;
    }
    let checkpoint2=Psig_verifyTweaked(this.signer, int_to_bytes(psigI2p,32), this.nonceA2, this.pubKeyDist, session_ctx2, this.tG);
    if(checkpoint2==false){
      return false;
    }
    this.psigI2p=psigI2p;

    //Compute partial signatures
    let psigR1=this.signer.Psign(this.nonceB1[0], this.sk, session_ctx1);
    let psigR2=this.signer.Psign(this.nonceB2[0], this.sk, session_ctx2);
    this.psigR2=psigR2;

    console.log("Partial verify:", this.signer.Psig_verify(psigR1, this.nonceB1[1], this.pubkey, session_ctx1));
    console.log("Partial verify:", this.signer.Psig_verify(psigR2, this.nonceB2[1], this.pubkey, session_ctx2));
  
    this.SIG_ABTX1p=this.signer.Partial_sig_agg([int_to_bytes(psigI1p), psigR1], session_ctx1);
    this.SIG_ABTX2p=this.signer.Partial_sig_agg([int_to_bytes(psigI2p), psigR2], session_ctx2);


    Message_R2=[psigR1, psigR2];
    this.state="waitI3";
    return Message_R2;//this message is broadcast onchain to unlock responder exit liquidity

  }

  //looking at Alice's unlocking, Bob can recompute the original signature
  FinalUnlock(UnlockSigAlice){
    let Message_R3=[];
    let SIG_ABTX1=UnlockSigAlice[0];
    UnlockSigAlice[0];

    let Recomputed_t=((this.signer.order + int_from_bytes(this.SIG_ABTX1p)) - int_from_bytes(SIG_ABTX1)) %this.signer.order;
   
    const session_ctx2=[this.aggnonce2, [ this.pubKeyDist, this.pubkey], [], [], this.tx2];//session_ctx=[aggnonce, pubkeys, [], [], msg];
    let psigI2=((this.signer.order+(this.psigI2p)-(Recomputed_t)))%this.signer.order;
    psigI2=int_to_bytes(psigI2);
    Message_R3=this.signer.Partial_sig_agg([psigI2, this.psigR2], session_ctx2);
    let x_aggpk=this.signer.curve.ForceXonly(this.aggpk);//x-only version for noncegen, allways 32
    
    let check=this.signer.Schnorr_verify(this.tx2, x_aggpk, Message_R3);

    console.log("final check:", check);

    this.state="idle";
    return Message_R3;//this message is broadcast onchain to unlock responder exit liquidity

  }


}

