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



import "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
/* import rip7212 */

import "../external/sha512/Sha2Ext.sol";

contract SCL_Ed25519Test is Test {


 function test_abc() public view {
    bytes32 low;
    bytes32 high;

    (high, low)=Sha2Ext.sha512("abc");
    //https://asecuritysite.com/encryption/md5?word=abc
    //console.log("%x %x",uint256(high), uint256(low));
    assertEq(high, 0xddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a);
    assertEq(low, 0x2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f);

    (high, low)=Sha2Ext.sha512(hex"616263");//equivalent vector input

    assertEq(high, 0xddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a);
    assertEq(low, 0x2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f);
    
    //https://www.di-mgt.com.au/sha_testvectors.html
    (high, low)=Sha2Ext.sha512("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
   
    assertEq(high,0x8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018 );
    assertEq(low,0x501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909);

 }

}