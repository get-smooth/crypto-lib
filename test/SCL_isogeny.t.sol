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
import "@solidity/fields/SCL_wei25519.sol";
import "@solidity/elliptic/SCL_Isogeny.sol";
import "@solidity/elliptic/SCL_mulmuladd_fullgen_b4.sol";


contract SCL_isogenyTest is Test {

 //test involutivity of Edwards/Weierstrass isogenies
 function test_isogeny_generator_ed25519() public {   
 uint256 genX=0x216936D3CD6E53FEC0A4E231FDD6DC5C692CC7609525A7B2C9562D608F25D51A;
 uint256 genY=0x6666666666666666666666666666666666666666666666666666666666666658;  
 uint256 resX;
 uint256 resY;
 (resX, resY)=Edwards2WeierStrass(genX, genY);
 assertEq(resX, gx);
 assertEq(resY, gy);
 
 //console.log(" Weierstrass: %x %x",resX, resY);

 (resX, resY)=WeierStrass2Edwards(resX, resY);
 assertEq(resX, genX);
 assertEq(resY, genY);//todo: correct Y return value
 
//console.log(" Recomputed edwards: %x %x",resX, resY);
 }

 function test_mulwithiso() public pure{
    //input secret key for edd25519
    uint256 expandedsec=31531604425972617034374315527056165422477269154623932846749706281462965132592;
    //expected public key

 }

//vectors extracted from https://asecuritysite.com/curve25519/ed
//https://crypto.stackexchange.com/questions/99798/test-vectors-points-for-ed25519
//Point 1G 5866666666666666666666666666666666666666666666666666666666666666 
//Point 2G, x= 0x36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e
//Point 5G x=0x49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233

 function test_ed25519() public {
   uint256 genX=0x216936D3CD6E53FEC0A4E231FDD6DC5C692CC7609525A7B2C9562D608F25D51A;
   uint256 genY=0x6666666666666666666666666666666666666666666666666666666666666658;  
   uint256 resX;
   uint256 resY;
   (resX, resY)=Edwards2WeierStrass(genX, genY);


   
 }

}