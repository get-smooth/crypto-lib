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

import { ec_mulmuladdX_asm} from "@solidity/elliptic/SCL_mulmuladd_am3_b4_inlined.sol";
import { ec_mulmuladdX} from "@solidity/elliptic/SCL_mulmuladd_am3_inlined.sol";

contract SCL_configTest is Test {

  SCL_ecdsa_secp256r1 ecdsa_secp256r1=new SCL_ecdsa_secp256r1();


 function test_compiling() public {

    console.log("Compiling success");
    assertEq(true,true);
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
 resX=ec_mulmuladdX(Q[0],Q[1], vec[0], 0);
 assertEq(0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978, resX);


 //edge case from FCL, Q=-4G
 uint256[4] memory vec2=[
102369864249653057322725350723741461599905180004905897298779971437827381725266,//x
    14047598098721058250371778545974983789701612908526165355421494088134814672697,//y
    94632330233094393099906091027057584450760066982961548963789323460936666616340,//u
    23658082558273598274976522756764396112690016745740387240947330865234166656879];//v
  
  (resX, resY)=ec_scalarmulN(1<<128, vec2[0], vec2[1]);

  Q=[102369864249653057322725350723741461599905180004905897298779971437827381725266,14047598098721058250371778545974983789701612908526165355421494088134814672697,
  0,0];

 resX=ec_mulmuladdX(Q[0],Q[1],  vec2[2], vec2[3]);
 console.log("resX=%x",resX);
 
 assertEq(93995665850302450053183256960521438033484268364047930968443817833761593125805, resX);
 

 return true;
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


 //ecdsa using the 4 dimensional shamir's trick
 function test_ecdsa_verif2() public  returns (bool){

   console.log("           * Shamir 4 dimensions");
   
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
   console.log(" OK");
   
   return res;
 }

//this function comes from the testing framework of Daimo
 function test_wycheproof() public{
 // This is the most comprehensive test, covering many edge cases. See vector
    // generation and validation in the test-vectors directory.
    uint cpt=0;
  
    console.log("           * Wycheproof");      
	   
        string memory file = "./test/vectors_wycheproof.jsonl";
        while (true) {
           
            string memory vector = vm.readLine(file);
            if (bytes(vector).length == 0) {
                break;
            }
             cpt=cpt+1;
           //console.log("%s",vector);//display all wycheproof vectors
	    
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
        console.log("%d vectors OK", cpt);
    }

 


 function libSCL_secp256r1() public returns (bool){
   bool res=true;
  
   res=res && test_ecdsa_verif2();
   test_wycheproof();
   test_edgeMul();

   return res;
 }

 

 function test_secp256r1() public returns (bool){
  
   console.log("test libSCL_secp256r1:");
   if(FIELD_OID!=_SECP256R1){//desactivate test if configuration is not set to secp256r1
      console.log("untested");
      return true;
   }
   bool res= libSCL_secp256r1();
   assertEq(res,true);

   if(res==true){
     console.log(" %s", "OK");
  }

   return res;
 }

}
