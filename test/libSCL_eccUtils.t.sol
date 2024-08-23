/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This library contains utils that provides OFFCHAIN computations, they are  provided as
/* an helper for integration, test and fuzzing BUT SHALL NOT USED ONCHAIN for performances and security reasons                  
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import "forge-std/Test.sol";

import "forge-std/Test.sol";

import "@solidity/lib/libSCL_ecdsab4.sol";

import "@solidity/fields/SCL_secp256r1.sol";
//import point on curve checking
import "@solidity/lib/libSCL_eccUtils.sol";


contract Test_eccutils is Test {
  

 //test all wycheproof keys are on curve and not pathologic
function test_goodkeys_wycheproof() public view{
  
 // This is the most comprehensive test, covering many edge cases. See vector
    // generation and validation in the test-vectors directory.
    uint cpt=0;
    uint256[10] memory Qpa;
    bool status=false;


   // console.log("           * Wycheproof");      
	   
        string memory file = "./test/vectors_wycheproof.jsonl";
        while (true) {
             string memory vector = vm.readLine(file);
            if (bytes(vector).length == 0) {
                break;
            }
             cpt=cpt+1;
         //  console.log("\n ------%s",vector);//display all wycheproof vectors
	    
            uint256 qx = uint256(stdJson.readBytes32(vector, ".x"));
            uint256 qy = uint256(stdJson.readBytes32(vector,".y"));
          //  uint256 r = uint256(stdJson.readBytes32(vector,".r"));
            uint256 s = uint256(stdJson.readBytes32(vector,".s"));
            bytes32 hash = stdJson.readBytes32(vector,".hash");
            bool expected =stdJson.readBool(vector, ".valid");
            string memory comment = stdJson.readString(vector, ".comment");

            if(expected)
            {
                  (status, Qpa)=SCL_ECCUTILS.SetKey(p, a, b, gx, gy, qx, qy);
                assertEq(status, true);
            }
        }
    }


    function test_weakkeys() public view{
        
        bool status=false;

        //identify weak keys for 4MSM multiplication
        uint256 qx=gx;
        uint256 qy=gy;
        //todo: add cases identified in weak_ecdsa_keys.md
        
        //the catch SHALL fail, as we are trying to use a weak key
        try SCL_ECCUTILS.SetKey(p, a, b, gx, gy, qx, qy) returns (bool val, uint256[10] memory Qpa) {
            status=false;
        } catch Error(string memory /*reason*/) {
            status=true;
        } 
       
        assertEq(status, true);

    }


}    
