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

import "forge-std/Test.sol";

/* SCL includes */
import {_SECP256R1} from "@solidity/include/SCL_mask.h.sol";
import {FIELD_OID} from "@solidity/include/SCL_field.h.sol";
import {ec_SetPrec } from"@solidity/include/SCL_elliptic.h.sol";

/* SCL libraries */
import "@solidity/lib/libSCL_secp256r1_prec.sol";
import "@solidity/lib/libSCL_secp256r1_utils.sol";


contract SCL_secp256r1_prec is Test {


 /* vector from http://point-at-infinity.org/ecc/nisttv
 k = 29852220098221261079183923314599206100666902414330245206392788703677545185283
 x = 9EACE8F4B071E677C5350B02F2BB2B384AAE89D58AA72CA97A170572E0FB222F
 y = 1BBDAEC2430B09B93F7CB08678636CE12EAAFD58390699B5FD2F6E1188FC2A78
 */
 function Invariant_ecdsa_verif() public returns (bool){

   address precomputations=address(uint160(bytes20("BecauseYouReSoSmooth")));
   SCL_ecdsa_secp256r1_prec ecdsa_secp256r1_prec=new SCL_ecdsa_secp256r1_prec();

   uint256 Qx=0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c;
   uint256 Qy=0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032;
   
   bytes memory bytecode_prec=ec_SetPrec(Qx,Qy);

   vm.etch(precomputations, bytecode_prec); //todo : replace with create

   uint256[5] memory vec=[
   0xbb5a52f42f9c9261ed4361f59422a1e30036e7c32b270c8807a419feca605023 ,
   0x741dd5bda817d95e4626537320e5d55179983028b2f82c99d500c5ee8624e3c4,
   0x974efc58adfdad357aa487b13f3c58272d20327820a078e930c5f2ccc63a8f2b,
   0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c ,
   0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032];

   return ecdsa_secp256r1_prec.verify(bytes32(vec[0]), vec[1], vec[2], precomputations);

 }

 function libSCLsecp256r1() public returns (bool){
   bool res=true;
  
   res=res && Invariant_ecdsa_verif();

   return res;
 }


 function test_secp256r1() public returns (bool){
  
   console.log("libSCL_secp256r1 with precomputations:");
   if(FIELD_OID!=_SECP256R1){//desactivate test if configuration is not set to secp256r1
      console.log("untested");
      return true;
   }
  bool res= libSCLsecp256r1();
   assertEq(res,true);
 }

}