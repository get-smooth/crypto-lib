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

import { SCL_FROST, SCL_trustedKeyGen } from './SCL_frost.mjs';


//random vector generation
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

//same as Musig2 test, tested OK
function test_aggnonce(){
   
    let frost = new SCL_FROST('secp256k1');
    
    console.log("/*************************** ");
    console.log("Test nonce_agg:");

    let pnonces= [
        "020151C80F435648DF67A22B749CD798CE54E0321D034B92B709B567D60A42E66603BA47FBC1834437B3212E89A84D8425E7BF12E0245D98262268EBDCB385D50641",
        "03FF406FFD8ADB9CD29877E4985014F66A59F6CD01C0E88CAA8E5F3166B1F676A60248C264CDD57D3C24D79990B0F865674EB62A0F9018277A95011B41BFC193B833",
        "020151C80F435648DF67A22B749CD798CE54E0321D034B92B709B567D60A42E6660279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798",
        "03FF406FFD8ADB9CD29877E4985014F66A59F6CD01C0E88CAA8E5F3166B1F676A60379BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798"
    ];
    let expected_agg1="035FE1873B4F2967F52FEA4A06AD5A8ECCBE9D0FD73068012C894E2E87CCB5804B024725377345BDE0E9C33AF3C43C0A29A9249F2F2956FA8CFEB55C8573D0262DC8";
    let expected_agg2="035FE1873B4F2967F52FEA4A06AD5A8ECCBE9D0FD73068012C894E2E87CCB5804B000000000000000000000000000000000000000000000000000000000000000000";
  

    let res=frost.Nonce_agg([pnonces[0], pnonces[1]]);
    console.log(res.equals(Buffer.from(expected_agg1,'hex')));


}

function test_noncegen()
{
    let frost = new SCL_FROST('secp256k1');
    
    console.log("/*************************** ");
    console.log("Test nonce_gen:");

    let rand_=Buffer.from("0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F",'hex');
    let secshare=Buffer.from("0202020202020202020202020202020202020202020202020202020202020202",'hex');;

    let pubshare=Buffer.from("024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766",'hex');;

    let group_pk=Buffer.from("0707070707070707070707070707070707070707070707070707070707070707",'hex');;
    let msg=Buffer.from("0101010101010101010101010101010101010101010101010101010101010101",'hex');;

    let extra_in=Buffer.from("0808080808080808080808080808080808080808080808080808080808080808",'hex');;
    let expected_secnonce=Buffer.from("6135CE36209DB5E3E7B7A11ADE54D3028D3CFF089DA3C2EC7766921CC4FB3D1BBCD8A7035194A76F43D278C3CD541AEE014663A2251DDE34E8D900EDF1CAA3D9",'hex');
    let expected_pubnonce=Buffer.from("02A5671568FD7AEA35369FE4A32530FD0D0A23D125627BEA374D9FA5676F645A6103EC4E899B1DBEFC08C51F48E3AFA8503759E9ECD3DE674D3C93FD0D92E15E631A",'hex');

    let res=frost.Nonce_gen_internal(rand_, secshare, pubshare, group_pk, msg, extra_in);

    console.log("res:",res, res[0].length);

    console.log(expected_secnonce.equals(Buffer.from(res[0].slice(0,64))));
    console.log(expected_pubnonce.equals(Buffer.from(res[1])));

}


(async () => {
    test_randomInterpolate_secret();
    test_aggnonce();
    test_noncegen();


})();