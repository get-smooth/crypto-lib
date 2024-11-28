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

export class SCL_Atomic_Swap
{
  constructor(curve) {
    this.signer=new SCL_Musig2(curve);
   
    this.curve=signer.curve;
  }

  Psign_adapt(psig, t){

   
    let sprime=(int_from_bytes(psig)+t ) % this.curve.order;
    let G= this.curve.GetBase(t);

    return [sprime, G.multiply(t)];
  }

  Untweak(t, psigA_adapt, psigB){
    const sABp=partial_sig_agg([psigA_adapt, psigB]);
  
    const sAB= (sABp - t)% secp256k1.CURVE.n;
  
    return sAB;
  }

}


function test_full_atomic_session(curve){
  const swapper= new SCL_Atomic_Swap(curve);
  const signer = swapper.signer;

  console.log("/*************************** ");
  console.log("Test full Atomic session on curve", Curve);

  console.log("  -Generate random keys");

    const sk1=signer.curve.Get_Random_privateKey();//this provides a 32 bytes array
    const sk2=signer.curve.Get_Random_privateKey();
    
    console.log("sk1=",sk1 );
    console.log("sk2=",sk2 );
    let seckeys=[sk1, sk2];

    const pubK1=signer.IndividualPubKey_array(sk1);
    const pubK2=signer.IndividualPubKey_array(sk2);

    console.log("pubK1=",pubK1 );
    console.log("pubK2=",pubK2 );
    
    const pubkeys=[pubK1, pubK2];

    let aggpk = signer.Key_agg(pubkeys)[0];//here aggpk is a 32 or 33 bytes compressed public key
    let x_aggpk=signer.curve.ForceXonly(aggpk);//x-only version for noncegen, allways 32

    console.log("Aggregated Pubkey:", aggpk);

    const msg1=Buffer.from("Unlock 1strkBTC on Starknet to Alice",'utf-8');
    console.log("msg1=",msg1);
    const msg2=Buffer.from("Unlock 1WBTC on Ethereum to Bob",'utf-8');
    console.log("msg2=",msg2);
    

  //nonce generation
  console.log(" -Generate random Nonces with commitment", aggpk);
  //diversification chain
  const extra_in1= Buffer.from(randomBytes(32));
  const extra_in2= Buffer.from(randomBytes(32));
  

  let nonceA1= signer.Nonce_gen(seckeys[0], pubkeys[0], x_aggpk,  msg1, extra_in1);
  let nonceB1= signer.Nonce_gen(seckeys[1], pubkeys[1], x_aggpk,  msg2, extra_in1);

  let nonceA2= signer.Nonce_gen(seckeys[0], pubkeys[0], x_aggpk,  msg1, extra_in2);
  let nonceB2= signer.Nonce_gen(seckeys[1], pubkeys[1], x_aggpk,  msg2, extra_in2);

  
  //aggregation of public nonces
  let aggnonce1 = signer.Nonce_agg([nonceA1[1].toString('hex'), nonceB1[1].toString('hex')]);
  let aggnonce2 = signer.Nonce_agg([nonceA2[1].toString('hex'), nonceB2[1].toString('hex')]);


  const session_ctx1=[aggnonce1, pubkeys, [], [], msg];
  const session_ctx2=[aggnonce2, pubkeys, [], [], msg];

  let pA1=signer.Psign(nonceA1[0], seckeys[0], session_ctx1);
  let pA2=signer.Psign(nonceA2[0], seckeys[0], session_ctx2);


  let pB1=signer.Psign(nonceB1[0], seckeys[0], session_ctx1);
  let pB2=signer.Psign(nonceB2[0], seckeys[0], session_ctx2);

  //Alice tweaks signatures 
  let t=int_from_bytes(signer.curve.Get_Random_privateKey());
  let atomic_ctx1=swapper.Psign_adapt(pA1, t);
  let atomic_ctx2=swapper.Psign_adapt(pA2, t);

  //todo:Bob checks compliance of tG, pA2p, pA1p, msg1, msg2


  //Bob compute sAB', then substract to obtain sAB
  let sAB1=swapper.Untweak(t,atomic_ctx1 );

  //




  console.log("p1=",p1);

}