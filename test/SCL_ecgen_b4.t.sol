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
import "@solidity/elliptic/SCL_mulmuladdX_fullgen_b4.sol";

 uint256 constant _2p255m1=0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
//ecFullGenMulmuladdX
contract SCL_secputils is Test {
//test for secp256r1 setting
function t_Edge() public {
uint256[3] memory vec=[
  115792089210356248762697446949407573529996955224135760342422259061068512044367,
  0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978,
  0xF888AAEE24712FC0D6C26539608BCF244582521AC3167DD661FB4862DD878C2E
 ];
 uint256 resX;

 uint256[4] memory Q=[uint256(0),0,0,0];

 resX=ecGenMulmuladdX(Q,  vec[0], 0);

 assertEq(0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978, resX);
 resX=2;

 uint256[10] memory Qpa=[uint256(0),0,0,0,p, a, gx, gy, gpow2p128_x, gpow2p128_y];

 //testing single Mul with g
 resX=ecGenMulmuladdX_store(Qpa,  vec[0], 0);

 assertEq(0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978, resX);


}


function test_Edge2() public {
uint256[3] memory vec=[
  115792089210356248762697446949407573529996955224135760342422259061068512044367,
  0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978,
  0xF888AAEE24712FC0D6C26539608BCF244582521AC3167DD661FB4862DD878C2E
 ];
 uint256 resX;
 uint caca;

 uint256[10] memory Qpa=[uint256(0),0,0,0,p, a, gx, gy, gpow2p128_x, gpow2p128_y];
 for(uint i=0;i<10;i++){
 resX=ecGenMulmuladdX_store(Qpa,  vec[0], 0);
 console.log("resX=%x", resX);
 assertEq(0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978, resX);

 }
 

}

uint256 constant p256r1 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

function test_Edge3() public{
uint256 res1;
uint256 res2;

uint256 qx=0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c;
uint256 qy=0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032;
uint256 q2p128_x=112495727131302244506157669471790202209849926651017016481532073180322115017576;
uint256 q2p128_y=88228053145992414849958298035823172674083888062809552550982514976029750463913;
 

 
uint256[4] memory Q=[qx, qy, q2p128_x, q2p128_y];

 
 
uint256[10] memory Qpaxy=[
  qx, qy, q2p128_x, q2p128_y,
  p256r1, a, gx, gy, gpow2p128_x, gpow2p128_y];
 


//res1=ecGenMulmuladdX_store(Qpaxy,  vec[0], 0);
 
}




function test_mem() public{
  uint256 spy;
  uint256 spy2;
  assembly{
    spy:=mload(0x40)
    let T1:=2
    spy2:=mload(0x40)
  }
 console.log("%x %x", spy, spy2);

}


function test_wrstcase_old() public {

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

//testing compilation time versus call data versions of 4 dimensional
function test_b4VSgenb4() public {

 uint256 resX;

 uint256[4] memory 
 Q=[102369864249653057322725350723741461599905180004905897298779971437827381725266,14047598098721058250371778545974983789701612908526165355421494088134814672697,
  18348424709969931834174091430613018498698081298566264338878701168549980217100,67978170286277163314572489353283187500322312916350454928267654971650586636935];
 
 uint256[10] memory Qpa=[Q[0], Q[1],Q[2],Q[3],p, a, gx, gy, gpow2p128_x, gpow2p128_y];
 uint i;

 resX=ecGenMulmuladdX(Q,  _2p255m1, _2p255m1);
 console.log("resX= %d %x",resX, resX);
 
 
 resX=ecGenMulmuladdX_store(Qpa,  _2p255m1, _2p255m1);
 console.log("resX= %d %x",resX, resX);

 resX=ecGenMulmuladdX(Q,115792089210356248762697446949407573529996955224135760342422259061068512044367,0);
 console.log("resX= %d %x",resX, resX);
 
 
 resX=ecGenMulmuladdX_store(Qpa,115792089210356248762697446949407573529996955224135760342422259061068512044367,0);
 console.log("resX= %d %x",resX, resX);
}

}