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


import{SCL_ecc} from './SCL_ecc.mjs';
import{SCL_Musig2} from './SCL_Musig2.mjs';
import { SCL_Atomic_Initiator, SCL_Atomic_Responder } from './SCL_atomic_swaps.mjs';


//example of full session with automata
//note that worst case is assumed (Bob read tweak from  Alice's signature)
function test_full_atomic_session_automatas(curve){
    console.log("/*************************** ");
    console.log("Full Atomic Swap session using curve:", curve);

    let signer=new SCL_Musig2(curve);

    console.log("signer:", signer);
    //generating keypairs
    let Initiator=new SCL_Atomic_Initiator(curve, signer.curve.Get_Random_privateKey());
    let Responder=new SCL_Atomic_Responder(curve, signer.curve.Get_Random_privateKey());

    //the transaction unlocking tokens for Alice and Bob, must be multisigned with Musig2
    //Alice want to compute msg1 signed by AB
    //Bob wants to compute msg2 signed by AB
    const tx1=Buffer.from("Unlock 1strkBTC on Starknet to Alice",'utf-8');
    const tx2=Buffer.from("Unlock 1WBTC on Ethereum to Bob",'utf-8');


    console.log("Initiator Start session");
    let Message_I1=Initiator.InitSession(tx1, tx2, Responder.pubkey); //Initiator sends I1 to responder offchain

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
    let UnlockSigBob=Responder.FinalUnlock(UnlockSigAlice);//final signature to Unlock chain2 token by Responder
    
    //todo: result is ok if UnlockSigBob is equal to classic multisig

}


(async () => {
    test_full_atomic_session_automatas('secp256k1');
    test_full_atomic_session_automatas('ed25519');

})();