/********************************************************************************************/
/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* License: This software is licensed under MIT License (and allways will)   
#/* Description: Testing contract for SCL implementation of rip7212                
#/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;




import "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
/* import rip7212 */

import "@solidity/lib/libSCL_RIP7212.sol";


uint constant NBTEST=1000;

contract Test_exeSCL_rip7212 is Test {


 //ecdsa using windowed 2 bits shamir's trick
 function test_secp256r1() public  view returns (bool){

   console.log("           * Shamir 4 dimensions");
   
  uint256[5] memory vec=[
   0xbb5a52f42f9c9261ed4361f59422a1e30036e7c32b270c8807a419feca605023 ,//message
   0x741dd5bda817d95e4626537320e5d55179983028b2f82c99d500c5ee8624e3c4,//r
   0x974efc58adfdad357aa487b13f3c58272d20327820a078e930c5f2ccc63a8f2b,//s
   0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c ,//Q start here
   0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032];
   bool res;


   for(uint i=0;i<NBTEST;i++)
   {
    res= SCL_RIP7212.verify(bytes32(vec[0]), vec[1], vec[2], vec[3], vec[4]);
   }

   //assertEq(res,true); 
   
   return res;
 }

 //ecdsa using the window+ shamir's trick, wycheproofing tests Daimo
 function test_rip7212_wycheproof() public view{
   
 // This is the most comprehensive test, covering many edge cases. See vector
    // generation and validation in the test-vectors directory.
    uint cpt=0;
  
   // console.log("           * Wycheproof");      
	   
        string memory file = "./test/vectors_wycheproof.jsonl";
        while (true) {
           
            string memory vector = vm.readLine(file);
            if (bytes(vector).length == 0) {
                break;
            }
             cpt=cpt+1;
         //  console.log("\n ------%s",vector);//display all wycheproof vectors
	    
            uint256 x = uint256(stdJson.readBytes32(vector, ".x"));
            uint256 y = uint256(stdJson.readBytes32(vector,".y"));
            uint256 r = uint256(stdJson.readBytes32(vector,".r"));
            uint256 s = uint256(stdJson.readBytes32(vector,".s"));
            bytes32 hash = stdJson.readBytes32(vector,".hash");
            bool expected =stdJson.readBool(vector, ".valid");
            string memory comment = stdJson.readString(vector, ".comment");
	    
            bool result = SCL_RIP7212.verify(hash, r, s, x, y);
	    
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

}