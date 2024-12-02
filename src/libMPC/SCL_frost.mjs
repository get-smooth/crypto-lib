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

import{SCL_Musig2} from './SCL_Musig2.mjs';

export class SCL_polynomials{

    constructor(modulus, coeffs){
        this.coeffs=coeffs;
        this.modulus=this.modulus;
    }


    Evaluate(x){
        let res=coeffs[0];//a0
        for(i=1;i<this.coeffs.length;i++){
            res=(this.MulMod(res,x)+(this.coeffs[i]))%this.modulus;
        }
        return res;
    }



}

export class SCL_trustedKeyGen
{
    constructor(curve,  sk, n, k) {

        this.signer=new SCL_Musig2(curve);
        this.sk=sk;
    
        this.pubkey=this.signer.IndividualPubKey_array(sk);
    
        this.n=0;
        this.k=0;
       
        this.pubshares=[];
        this.secshares=[];

      }

      //in the future, improve it with a PRNG using secret and random generator
      GetRandomElement(){
        return this.signer.curve.Get_Random_privateKey()
      }

      KeyGen(n, k){
        this.n=n;//maximum number of participants
        this.k=k;//minimum number of participants = degree of polynomial-1


        //generate secret shares: 
        for(i=0;i<this.k;i++){
            
        }

        let Rs1 = this.curve.PointCompress(P.multiply(bk_1));
        let Rs2 = this.curve.PointCompress(P.multiply(bk_2));

        let pubnonce =  Buffer.concat([Rs1, Rs2]);
        let secnonce =  Buffer.concat([k_1, k_2, pk]);
    

      }

}