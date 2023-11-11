/********************************************************************************************/
/*
/*     ___                _   _       ___               _         _    _ _    
/*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
/*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
/*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
/*                                         |__/|_|           
/*              
/* Copyright (C) 2023 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
/* License: This software is licensed under MIT License                                        
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


//DRNG
import {random_ctx,  } from "@solidity/include/SCL_DRNG.h.sol";


//import BIP340 keygen
import {ec_KeyGenX} from "@solidity/protocols/SCL_eckeygen.sol";

uint256 constant nusers=2;
uint256 constant _MU=2;

string constant Nonce_separator="nonce";
string constant Agg_separator="nonce";
string constant Sig_senonceparator="sig";

/******************* HASH FUNCTIONS with Domain separation*/
//H_Nonce = hash(Xtilde||Ris||m)
//#Xtilde is the public key aggregation computed at first round
function hash_nonce(uint256 XtildeX, uint256[_MU] memory ephemerals, bytes message) returns(uint256 hashnonce){
  hashnonce=sha256(Nonce_separator+abi.encodePacked(XtildeX)+abi.encodePacked(ephemerals)+abi.encodePacked(message));
}

//expected public keys format is xonly
function hash_agg(uint256[_nusers] L, uint256 KpubX) returns(uint256 hashAgg){
  hashAgg=sha256(Agg_separator+abi.encodePacked(L)+abi.encodePacked(KpubX));
}

function hash_sig(uint256 XtildeX, uint256 Rx, bytes message ) returns(uint256 hashSig){
  hashSig=sha256(Sig_senonceparator+abi.encodePacked(XtildeX)+abi.encodePacked(Rx))+abi.encodePacked(message));
}

/******************* OFF CHAIN PROTOCOL (sensitive data)*/
/* Warning : Offchain code is not meant to be used with funds ! It is for demonstration only as private keys shall never
exist on chain*/

function Musig2_KeyAgg(){}
function Musig2_AggRound1(){}
function Musig2_AggRound2(){}


/***********************Single user functions***************************************/
/* Round1 from single signer view
# in a practical version, random element shall be replaced by rfc6979 adaptation    */

function Musig2_Sign_Round1(random_ctx memory RandCtx) view
returns (uint256[_MU] nonces, uint256[_MU] ephemerals)
{
   for(uint256 j=0;j<_MU;j++){
    ( RandCtx, nonces[j])=SCL_RandomUint256_Generate(RandCtx);
   }
   //TODO: check where is x only, replace by base point mul
   ephemerals[j]=ec_scalarmulN(nonces[j]);

   returns(nonces, ephemerals)
}


function Musig2_Sign_Round2(random_ctx memory RandCtx,
uint256 Kpriv,
uint256 ai, uint256 KeyAggX,uint256 KeyAggY,
uint256[_MU] nonces, uint256[_MU] ephemerals, //Round1 output
bytes message
) view
returns (uint256 R, uint256 s, uint256 c)
{
   uint256 b=H_Nonce(KeyAggx, ephemerals, message);
   uint256 X=0;
   uint256 Y=0;
   uint256 bpowj=1;
   uint256 Rx=0;
   uint256 Ry=0;
   
   b=hash_nonce(KeyAggX, ephemerals, message);

   Rx=ephemerals[0];
   //Ry==ec_Decompress(X);, TODO: code Point decompression
   for(uint256 j=1;j<_MU;j++){
    //Y=ec_Decompress(X);, TODO: code Point decompression
    (X,Y)=ec_scalarmulN(bpowj, ephemerals[0], Y);
    (Rx, Ry)=ec_AddN(Rx, Ry, 1, 1, X, Y);
    bpowj=mulmod(b,bpowj,n);
   }
   c=hash_sig(KeyAggX, Rx, message);
   s=mulmod(mulmod(c, ai, n), Kpriv, n);

   s=addmod(s, mulmod(b, nonces[0]));
   bpowj=b;

   for(uint256 j=1;j<_MU;j++){
    s=addmod(s, mulmod(bpowj, nonces[j]))
   }

   returns(Rx, s, c)
}



/******************* OFF/ON CHAIN */
/* Those could be pushed on chain, but might be expansive
/***********************Aggregator functions****************************************/





