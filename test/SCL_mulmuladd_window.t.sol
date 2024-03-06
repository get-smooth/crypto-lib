/********************************************************************************************/
/*
/*  _____   _       _       _     _____                  _        _      _ _     
/* / ____/\| |/\ /\| |/\ /\| |/\ / ____|                | |      | |    (_) |    
/*| (___ \ ` ' / \ ` ' / \ ` ' /| |     _ __ _   _ _ __ | |_ ___ | |     _| |__  
/* \___ \_     _|_     _|_     _| |    | '__| | | | '_ \| __/ _ \| |    | | '_ \ 
/* ____) / , . \ / , . \ / , . \| |____| |  | |_| | |_) | || (_) | |____| | |_) |
/*|_____/\/|_|\/ \/|_|\/ \/|_|\/ \_____|_|   \__, | .__/ \__\___/|______|_|_.__/ 
/*                                            __/ | |                            
/*                                           |___/|_|                           
/*              
/* Copyright (C) 2023 - Renaud Dubois - This file is part of SCL (S*** CryptoLib) project
/* License: This software is licensed under MIT License                                        
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import {_ED25519} from "@solidity/include/SCL_mask.h.sol";
import {MINUS_1, FIELD_OID} from "@solidity/include/SCL_field.h.sol";

import "@solidity/elliptic/SCL_mulmuladd_gen_windowed.sol";
import "@solidity/elliptic/SCL_mulmuladd_gen_b4.sol";
import "forge-std/Test.sol";
import "@solidity/elliptic/SCL_mulmuladd_fullgen_b4.sol";
import "@solidity/elliptic/SCL_gensw.sol";


contract SCL_mulmuladd_window is Test {

   function viewPrec(bytes memory Prec, uint256 index) public view
   {
    uint256 X;
    uint256 Y;
    uint256 ZZ;
    uint256 ZZZ;
    uint256 read;

    assembly{
        read:=mul(index, 128)
        X:=mload(add(read, Prec))
        Y:=mload(add(read, add(Prec, 32)))
        ZZ:=mload(add(read, add(Prec, 64)))
        ZZZ:=mload(add(read, add(Prec, 96)))
    }
   //console.log("\n----------- %x",index);
   // console.log("%x %x %x",X, Y, ZZ);
    (X,Y)=ec_Normalize(X,Y,ZZ,ZZZ);

   // console.log("\n %d %d",X, Y);
   }

   function test_window() public  returns (bool){

   //allocating 16 points of 4 coordinates over a 32 bytes field
   bytes memory Preco = new bytes(16*4*32);

   //This is Q=3G
   uint256 qx=0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c;
   uint256 qy=0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032;
   
   Preco=Window(qx, qy);

   console.logBytes(Preco);
   console.log("Points:");
   /*
   for(uint i=0;i<16;i++){
        viewPrec(Preco,i) ;
   }
   */
   test_edgeMul();
test_edgeMul();
test_edgeMul();
test_edgeMul();
test_edgeMul();
test_edgeMul();
test_edgeMul();
test_edgeMul();
test_edgeMul();
test_edgeMul();



    return true;
   }

   
 /* vector from http://point-at-infinity.org/ecc/nisttv
//k = 115792089210356248762697446949407573529996955224135760342422259061068512044367
//x = 7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978
//y = F888AAEE24712FC0D6C26539608BCF244582521AC3167DD661FB4862DD878C2E*/
//edge case for Shamir 
function test_edgeMul() public returns (bool)
{
 console.log("           * ec_mulmuladd edge cases");



uint256[3] memory vec=[
  115792089210356248762697446949407573529996955224135760342422259061068512044367,
  0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978,
  0xF888AAEE24712FC0D6C26539608BCF244582521AC3167DD661FB4862DD878C2E
 ];
 uint256 resX;
 uint256 resY;
 uint256[4] memory Q=[uint256(0),0,0,0];

 //(resX, resY)=ec_scalarmulN(vec[0], vec[1], vec[2]);
 resX=ecGenMulmuladdW(Q[0],Q[1], vec[0], 0);
 assertEq(0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978, resX);
 return true;
 }
 
}

//expected values from sage:
/* Q+G
//(102369864249653057322725350723741461599905180004905897298779971437827381725266 : 101744491111635190512325668403432589740384530506764148840112137220732283181254 : 1)


3*G
(42877656971275811310262564894490210024759287182177196162425349131675946712428 : 61154801112014214504178281461992570017247172004704277041681093927569603776562 : 1)
3*G+3*Q
(52521004185641536627266600536804816931535329133355539962020980193802383057860 : 3365321999886721389269937144276711091585627196865605815969312301872807444947 : 1)
 2*G+3*Q
(28412803729898893058558238221310261427084375743576167377786533380249859400145 : 65403602826180996396520286939226973026599920614829401631985882360676038096704 : 1)
 G+3*Q
(93611846365601674425599200647886473617443872040541410036779615417472400060991 : 61299672808462629900136024686264045542397545919962042795596947287593974695795 : 1)

*/