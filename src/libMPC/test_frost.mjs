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

import { SCL_trustedKeyGen } from './SCL_frost.mjs';

function test_randomInterpolate_secret(){
 
 let curve=new SCL_ecc('secp256k1');
 let sk=curve.Get_Random_privateKey();

 let dealer=new SCL_trustedKeyGen( 'secp256k1',sk, 12,4);

 console.log("Consistency secret/public shares:",dealer.Check_Shares());
 //erasing to prove Reed Solomon like recovery of missing shares
 

 let rec_secret=dealer.Interpolate_group_seckey(dealer.secshares);
 console.log("interpolating secret:", rec_secret==int_from_bytes(sk));

 let rec_public=dealer.Interpolate_group_pubkey(dealer.pubshares, dealer.ids);

 console.log("interpolating public keys", Buffer.from(rec_public).equals(dealer.pubkey));
}




(async () => {
    test_randomInterpolate_secret();



})();