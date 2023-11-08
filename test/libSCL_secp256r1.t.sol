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


import {_SECP256R1} from "@solidity/include/SCL_mask.h.sol";
import {FIELD_OID} from "@solidity/include/SCL_field.h.sol";
import "forge-std/Test.sol";
import "@solidity/lib/libSCL_secp256r1.sol";


contract SCL_configTest is Test {

  SCL_ecdsa_secp256r1 ecdsa_secp256r1=new SCL_ecdsa_secp256r1();


 function test_compiling() public {

    console.log("Compiling success");
    assertEq(true,true);
 }

 /* vector from http://point-at-infinity.org/ecc/nisttv
 k = 29852220098221261079183923314599206100666902414330245206392788703677545185283
 x = 9EACE8F4B071E677C5350B02F2BB2B384AAE89D58AA72CA97A170572E0FB222F
 y = 1BBDAEC2430B09B93F7CB08678636CE12EAAFD58390699B5FD2F6E1188FC2A78
 x128=53488047128247301694364623372497486454260727333611202490371945462006853324918
 y128=87541140221172626774714648024541831781902994325813016789386069147468989318121
 */
 function Invariant_ecdsa_verif() public returns (bool){

  
   uint256[7] memory vec=[
   0xbb5a52f42f9c9261ed4361f59422a1e30036e7c32b270c8807a419feca605023 ,
   0x741dd5bda817d95e4626537320e5d55179983028b2f82c99d500c5ee8624e3c4,
   0x974efc58adfdad357aa487b13f3c58272d20327820a078e930c5f2ccc63a8f2b,
   0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c ,
   0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032,
   112495727131302244506157669471790202209849926651017016481532073180322115017576,
   88228053145992414849958298035823172674083888062809552550982514976029750463913];
   

   bool res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4]);
   

   
   return res;
 }


 //WIP: this is failing
 function test_ecdsa_verif2() public  returns (bool){


   uint256[7] memory vec=[
   0xbb5a52f42f9c9261ed4361f59422a1e30036e7c32b270c8807a419feca605023 ,
   0x741dd5bda817d95e4626537320e5d55179983028b2f82c99d500c5ee8624e3c4,
   0x974efc58adfdad357aa487b13f3c58272d20327820a078e930c5f2ccc63a8f2b,
   0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c ,
   0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032,
   112495727131302244506157669471790202209849926651017016481532073180322115017576,
   88228053145992414849958298035823172674083888062809552550982514976029750463913];
   
   bool res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4], vec[5], vec[6]);
   


   assertEq(res,true); 
   assertEq(true,true); 
   
   return res;
 }

 function libSCLsecp256r1() public returns (bool){
   bool res=true;
  
   res=res && Invariant_ecdsa_verif();
 
   return res;
 }

 

 function test_secp256r1() public returns (bool){
  
   console.log("test libSCL_secp256r1:");
   if(FIELD_OID!=_SECP256R1){//desactivate test if configuration is not set to secp256r1
      console.log("untested");
      return true;
   }
   bool res= libSCLsecp256r1();
   assertEq(res,true);

   if(res==true){
     console.log(" %s", "OK");
  }

   return res;
 }

}