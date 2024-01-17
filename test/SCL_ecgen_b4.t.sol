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


import {_ED25519} from "@solidity/include/SCL_mask.h.sol";
import {MINUS_1, FIELD_OID} from "@solidity/include/SCL_field.h.sol";

import "@solidity/elliptic/SCL_mulmuladd_am3_inlined.sol";
import "@solidity/elliptic/SCL_mulmuladd_gen_b4.sol";
import "forge-std/Test.sol";

 uint256 constant _2p255m1=0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

contract SCL_secputils is Test {
//test for secp256r1 setting
function test_Edge() public {
uint256[3] memory vec=[
  115792089210356248762697446949407573529996955224135760342422259061068512044367,
  0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978,
  0xF888AAEE24712FC0D6C26539608BCF244582521AC3167DD661FB4862DD878C2E
 ];
 uint256 resX;

 uint256[4] memory Q=[uint256(0),0,0,0];

 resX=ecGenMulmuladdX(Q,  vec[0], 0);
 assertEq(0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978, resX);


}


function test_worstcase_old() public {

 uint256 resX;

 uint256[4] memory 
 Q=[102369864249653057322725350723741461599905180004905897298779971437827381725266,14047598098721058250371778545974983789701612908526165355421494088134814672697,
  18348424709969931834174091430613018498698081298566264338878701168549980217100,67978170286277163314572489353283187500322312916350454928267654971650586636935];
 
 uint i;

 for(i=0;i<10;i++){
 resX=ec_mulmuladdX(Q[0],Q[1], _2p255m1, _2p255m1);
 console.log("resX=",resX);
 }

}

function test_worstcase() public {

 uint256 resX;

 uint256[4] memory 
 Q=[102369864249653057322725350723741461599905180004905897298779971437827381725266,14047598098721058250371778545974983789701612908526165355421494088134814672697,
  18348424709969931834174091430613018498698081298566264338878701168549980217100,67978170286277163314572489353283187500322312916350454928267654971650586636935];
 

 uint i;

 for(i=0;i<10;i++){
 resX=ecGenMulmuladdX(Q,  _2p255m1, _2p255m1);
 console.log("resX=",resX);
 }

}

}