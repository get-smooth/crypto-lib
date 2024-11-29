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

function  Psign_adapt(psig, t){

    let sprime=(int_from_bytes(psig)+t ) % this.curve.order;
    
    return sprime;
  }

function  Untweak(t, psigA_adapt, psigB){
    const sABp=partial_sig_agg([psigA_adapt, psigB]);
  
    const sAB= (sABp - t)% secp256k1.CURVE.n;
  
    return sAB;
  }



/********************************************************************************************/
/* INITIATOR AUTOMATA*/   
/********************************************************************************************/
export class SCL_Atomic_Initiator{

  constructor(curve, pubkey, sk) {

    this.signer=new SCL_Musig2(curve);
    this.pubkey=pubkey;
    this.sk=sk;
    this.state="idle";

    this.nonceA1=0;
    this.nonceA2=0;
    
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

  InitSession(tx1, tx2)
  {

    this. nonceA1= signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  tx1, extra_in1);
    this. nonceA2= signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  tx2, extra_in2);
    this.tx1=tx1;
    this.tx2=tx2;
    
    let Message_I1=[tx1, tx2, nonceA1[1], nonceA2[1]];

    this.state="waitR1"
    return Message_I1;//this message is broadcast offchain
  }

  PartialSign_Tweaked(Message_R1){
    let Message_I2=[];

    this.nonceB1=Message_R1[2];
    this.nonceB2=Message_R1[3];
    
    let aggnonce1 = signer.Nonce_agg([nonceA1[1].toString('hex'), nonceB1.toString('hex')]);
    let aggnonce2 = signer.Nonce_agg([nonceA2[1].toString('hex'), nonceB2.toString('hex')]);
    
    const session_ctx1=[aggnonce1, [this.pubkey, Message_R1[4]], [], [], this.tx1];
    const session_ctx2=[aggnonce2, [this.pubkey, Message_R1[4]], [], [], this.tx2];


    let psigI1=signer.Psign(nonceA1[0], this.sk, session_ctx1);
    let psigI2=signer.Psign(nonceA2[0], this.sk, session_ctx2);
    

    this.t=int_from_bytes(signer.Get_Random_privateKey());
    let G= this.curve.GetBase(t);
    this.tG=G.multiply(t);


    let psigI1p=Psign_adapt(psigI1,t)
    let psigI2p=Psign_adapt(psigI2,t)

    Message_I2=[psigI1p, psigI2p, this.tG];

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
  
  constructor(curve, pubkey, sk) {

    this.signer=new SCL_Musig2(curve);
    this.pubkey=pubkey;
    this.sk=sk; 
    this.state="idle";

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
    let tx1=Message_I1[0];
    let tx2=Message_I1[1];

    let nonceA1= Message_I1[2];
    let nonceA2= Message_I1[3];

    let nonceB1= signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  tx1, extra_in1);
    let nonceB2= signer.Nonce_gen(this.sk, this.pubkey, x_aggpk,  tx2, extra_in2);

    let aggnonce1 = signer.Nonce_agg([nonceA1.toString('hex'), nonceB1[1].toString('hex')]);
    let aggnonce2 = signer.Nonce_agg([nonceA2.toString('hex'), nonceB2[1].toString('hex')]);
    
    let Message_R1=[aggnonce1, aggnonce2, nonceB1[1], nonceB2[1], this.pubkey];

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


//example of full session with automata
//note that worst case is assumed (Bob read tweak from  Alice's signature)
function test_full_atomic_session_automatas(curve){
    let signer=new SCL_Musig2(curve);

    //generating keypairs
    let Initiator=new SCL_Atomic_Initiator(curve, signer.curve.Get_Random_privateKey());
    let Responder=new SCL_Atomic_Responder(curve, signer.curve.Get_Random_privateKey());

    //the transaction unlocking tokens for Alice and Bob, must be multisigned with Musig2
    //Alice want to compute msg1 signed by AB
    //Bob wants to compute msg2 signed by AB
    const msg1=Buffer.from("Unlock 1strkBTC on Starknet to Alice",'utf-8');
    const msg2=Buffer.from("Unlock 1WBTC on Ethereum to Bob",'utf-8');


    console.log("Initiator Start session");
    let Message_I1=Initiator.InitSession(msg1, msg2); //Initiator sends I1 to responder offchain

    console.log("Responder Start session");
    let Message_R1=Responder.RespondInit(Message_I1);//Respondeur sends R1 to Initiator offchain

    console.log("Initiator Partial Sign and tweak");
    let Message_I2=Initiator.PartialSign_Tweaked(Message_R1);//Initiator sends I2 to responder offchain
    //At this Point Alice and Bob locks the funds to multisig address on chain 1 and chain 2

    console.log("Responder Check and Partial Sign");
    let Message_R2=Responder.PartialSign(Message_I2);//Respondeur sends R2 to Initiator offchain

    console.log("Initiator Signature Aggregation and Unlock");
    let UnlockSigAlice=Initiator.FinalUnlock(Message_R2);//final signature to Unlock chain1 token by Initiator

    console.log("Responder Signature Aggregation and Unlock");
    let UnlockSigBob=Initiator.FinalUnlock(UnlockSigAlice);//final signature to Unlock chain2 token by Responder
    
    //todo: result is ok if UnlockSigBob is equal to classic multisig

}