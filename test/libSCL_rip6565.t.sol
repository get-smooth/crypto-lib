/********************************************************************************************/
/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* Description: Testing contract for SCL implementation of rip6565
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


//vectors extracted from https://asecuritysite.com/curve25519/ed
//https://crypto.stackexchange.com/questions/99798/test-vectors-points-for-ed25519
//Point 1G 5866666666666666666666666666666666666666666666666666666666666666 , LSB first
//Point 2G, x= 0x36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e
//Point 5G x=0x49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233


import "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";


import "@solidity/lib/libSCL_rip6565.sol";


//WIP : current fonctions prove that ed25519 ecc part is correctly implemented, SHA512 need to be integrated for full eddsa
contract SCL_Ed25519Test is Test {


 function test_BaseMul() public view {
  uint256 resX;


  (resX,)=SCL_RIP6565.BasePointMultiply_Edwards(2);
  assertEq(resX, 0x36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e);//expected 2G result
  
  (resX,)=SCL_RIP6565.BasePointMultiply_Edwards(5);
   assertEq(resX, 0x49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233);//expected 5G result
 
 }

 function test_expandSecret()public view {
    uint256 KpubC;
    uint256 expSec;
    //vector 1 from rfc8032
    uint256 secret1=0x4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb;
    uint256 expected1=0x3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c;

    (KpubC,expSec)=SCL_RIP6565.ExpandSecret(secret1);
    assertEq(KpubC, expected1);//expected public key
 
    //vector 2 from rfc8032
   uint256 secret2=0x3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c;
   

    //vector 3 input secret key, lsb first
    uint256 secret3=0xc5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7;
    //expected public key, lsb fist
    uint256 expected3=0xfc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025;

    (KpubC,expSec)=SCL_RIP6565.ExpandSecret(secret3);
    assertEq(KpubC, expected3);//expected public key       
 }


 function test_Fuzz_ed255sqrtmod2(uint256 x) public {
        uint256 val = mulmod(x, x, p);
        uint256 rac = SqrtMod(val);
       
        assertEq(mulmod(rac, rac, p), val);
    }



}