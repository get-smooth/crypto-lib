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
import {stdJson} from "forge-std/StdJson.sol";
import "@solidity/lib/libSCL_secp256r1.sol";
import {ec_scalarmulN} from  "@solidity/elliptic/SCL_ecutils.sol";

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
 function test_ecdsa_verif() public returns (bool){

  
   uint256[7] memory vec=[
   0xbb5a52f42f9c9261ed4361f59422a1e30036e7c32b270c8807a419feca605023 ,
   0x741dd5bda817d95e4626537320e5d55179983028b2f82c99d500c5ee8624e3c4,
   0x974efc58adfdad357aa487b13f3c58272d20327820a078e930c5f2ccc63a8f2b,
   0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c ,
   0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032,
   112495727131302244506157669471790202209849926651017016481532073180322115017576,
   88228053145992414849958298035823172674083888062809552550982514976029750463913];
   

   bool res= ecdsa_secp256r1.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4]);
   
   assertEq(res,true); 

   
   return res;
 }


 //WIP: this is failing
 function test_ecdsa_verif2() public  returns (bool){

   console.log("Test with Shamir 4 dimensions");
   
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
   //assertEq(true,true); 
   console.log("Assert OK");
   
   return res;
 }

//this function comes from the testing framework of Daimo
 function test_wycheproof() public{
 // This is the most comprehensive test, covering many edge cases. See vector
    // generation and validation in the test-vectors directory.
  
        string memory file = "./test/vectors_wycheproof.jsonl";
        while (true) {
            string memory vector = vm.readLine(file);
            if (bytes(vector).length == 0) {
                break;
            }
	    console.log("%s",vector);
	    
            uint256 x = uint256(stdJson.readBytes32(vector, ".x"));
            uint256 y = uint256(stdJson.readBytes32(vector,".y"));
            uint256 r = uint256(stdJson.readBytes32(vector,".r"));
            uint256 s = uint256(stdJson.readBytes32(vector,".s"));
            bytes32 hash = stdJson.readBytes32(vector,".hash");
            bool expected =stdJson.readBool(vector, ".valid");
            string memory comment = stdJson.readString(vector, ".comment");
	    uint256 x128;
	    uint256 y128;
	    
	    (x128, y128)=ec_scalarmulN(1<<128, x,y);
		
		
            bool result = ecdsa_secp256r1.verify(hash, r, s, x, y, x128, y128);
	    
            string memory err = string(
                abi.encodePacked(
                    "exp ",
                    expected ? "1" : "0",
                    ", we return ",
                    result ? "1" : "0",
                    ": ",
                    comment
                )
            );
            assertTrue(result == expected, err);
        }
    }

 


 function libSCLsecp256r1() public returns (bool){
   bool res=true;
  
   res=res && test_ecdsa_verif2();
   test_wycheproof();
   
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
