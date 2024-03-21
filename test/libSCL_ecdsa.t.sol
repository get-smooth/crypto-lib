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

import "@solidity/lib/libSCL_ecdsab4.sol";
import "@solidity/fields/SCL_secp256r1.sol";


contract SCL_ECDSATest is Test {
 //ecdsa using the 4 dimensional shamir's trick
 function test_secp256r1() public  returns (bool){

   console.log("           * Shamir 4 dimensions");
   
   
  uint256[7] memory vec=[
   0xbb5a52f42f9c9261ed4361f59422a1e30036e7c32b270c8807a419feca605023 ,//message
   0x741dd5bda817d95e4626537320e5d55179983028b2f82c99d500c5ee8624e3c4,//r
   0x974efc58adfdad357aa487b13f3c58272d20327820a078e930c5f2ccc63a8f2b,//s
   0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c ,//Q start here
   0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032,
   112495727131302244506157669471790202209849926651017016481532073180322115017576,
   88228053145992414849958298035823172674083888062809552550982514976029750463913];
   
   uint256[10] memory Qpa=[vec[3], vec[4], vec[5], vec[6] ,p, a, gx, gy, gpow2p128_x, gpow2p128_y];


   bool res= SCL_ECDSAB4.verify(bytes32(vec[0]), vec[1], vec[2], Qpa,n);
   


   //assertEq(res,true); 
   //assertEq(true,true); 
   console.log(" Not tested");
   
   return res;
 }
}