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

    //value of weak keys were also partially independantly found via Guido's work
    function test_weakkeys() public view returns (bool){
        
        bool status=false;

        //identify weak keys as identified by CRX report
       
        //value 2Q, 3Q, 2G, 3G ... computed using sage
        //1. Q=G
        uint256 qx=gx;//1.Q=G
        uint256 qy=gy;
       
        (status,)=SCL_ECCUTILS.SetKey(p, a, b, gx, gy, qx, qy);
        assertEq(status, false);
        //2. 2Q=G
        qx=19439240795854216504166878352080480852025048076250165894565412345120149900726;
        qy=64185496424002857229093033340967490116833136543672130696164427119171088715107;
        (status,)=SCL_ECCUTILS.SetKey(p, a, b, gx, gy, qx, qy);
        assertEq(status, false);
        //3. 2Q=-G
        qx=19439240795854216504166878352080480852025048076250165894565412345120149900726;
        qy=51606592786353391533604413608440083413253006871618183499369204189696009138844;
          (status,)=SCL_ECCUTILS.SetKey(p, a, b, gx, gy, qx, qy);
        assertEq(status, false);
      
        //4. 3Q=G

        qx= 36858631515729577427618021587181665754426975973028251330501583611661900650952;
        qy= 57614611834006547571837437085124862610314612006698381665563836969722143801436;
        (status,)=SCL_ECCUTILS.SetKey(p, a, b, gx, gy, qx, qy);
        assertEq(status, false);
      
        //5. 3Q=-2G
        qx= 47820944831959596514351589625154938811624096318765624397616398316301423766546;
        qy= 109730970122496639866270775665754787707917542520773780854335396537559893617185;
        (status,)=SCL_ECCUTILS.SetKey(p, a, b, gx, gy, qx, qy);
         assertEq(status, false);
         

         return true;
    }


}    
