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


  (resX,)=SCL_RIP6565.BasePointMultiply(2);
  assertEq(resX, 0x36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e);//expected 2G result
  
  (resX,)=SCL_RIP6565.BasePointMultiply(5);
   assertEq(resX, 0x49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233);//expected 5G result
 
 }


}