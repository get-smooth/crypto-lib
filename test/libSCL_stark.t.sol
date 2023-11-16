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


import {_STARKCURVE} from "@solidity/include/SCL_mask.h.sol";
import {FIELD_OID} from "@solidity/include/SCL_field.h.sol";
import {ec_mulmuladdX} from "@solidity/include/SCL_ecmulmuladd.h.sol";


import {Schnorr_sign, Schnorr_verify} from "@solidity/protocols/SCL_schnorr.sol";

import "forge-std/Test.sol";

import "@solidity/lib/libSCL_stark4337.sol";



contract SCL_StarkCurveTest is Test {

 //minimal vector generated using FCL_sage
 function stark_ec_mulmuladdX_t() public returns (bool){
   
   console.log("           * ec_mulmuladdX:");
   bool res=true;
   uint256 k= addmod(n, p-12,p);
   //expected multiplication result of k by (gx, gy) is (Rx, Ry)
   uint256 Rx=2887847313723422212839457588089656810396956397841585991334919802801880312483;
   //uint256 Ry=1116945807962327192421077193225578460521836318565509457667936234770658492375;

   uint256 resX=ec_mulmuladdX(0, 0, k, 0);

   //console.log("k= %x resX %x \n expected= %x", k, resX, Rx);
   assertEq(Rx, resX);
   
   return res;
 }

 
 //minimal vector generated using FCL_sage
 function stark_verify_t() public returns (bool flag_verif){
   
   console.log("           * ec_mulmuladdX:");
   bool res=true;
   uint256 k= addmod(n, p-12,p);
   //expected multiplication result of k by (gx, gy) is (Rx, Ry)
   uint256 Rx=2887847313723422212839457588089656810396956397841585991334919802801880312483;
   uint256 Ry=1116945807962327192421077193225578460521836318565509457667936234770658492375;

   uint256 s;
   uint256 e;
   string message="I don't ever wanna feel Like I did that day, under the Stark Bridge";//because why not

   (s,e)=Schnorr_sign(bytes32(message), k);
   flag_verif=Schnorr_verify(bytes32(message), s,e, Rx, Ry );

   //console.log("k= %x resX %x \n expected= %x", k, resX, Rx);
   assertEq(Rx, resX);
   
   return res;
 }

 function test_libSCL_starkcurve() public returns (bool){
  
   console.log("test libSCL_stark:");
   
   if(FIELD_OID!=_STARKCURVE){//desactivate test if configuration is not set to secp256r1
      console.log("               untested");
      return true;
   }
   bool res= stark_ec_mulmuladdX_t();
   assertEq(res,true);

   if(res==true){
     console.log(" %s", "OK");
  }
   else{
    console.log(" %s", "NOK");
   }

   return res;
 }

}