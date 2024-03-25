/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This file implements the eddsa verification protocol over secp256r1 as specified by RFC8032.                       
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import "@solidity/hash/SCL_sha512.sol";
//5.1.5.  Key Generation


//the name of the library 
library SCL_EDDSA{

 function HashSecret(uint256 secret) public pure returns (uint256 expanded){
   uint64[16] memory buffer; 
   secret=SCL_sha512.Swap256(secret);
   uint256 a; 
   uint256 low;

   buffer[0]=uint64((secret>>192)&0xffffffffffffffff);
   buffer[1]=uint64((secret>>128)&0xffffffffffffffff);
   buffer[2]=uint64((secret>>64)&0xffffffffffffffff);
   buffer[3]=uint64(secret&0xffffffffffffffff);
   buffer[4]=0x80;
   buffer[15]=0x100;//length is 256 bits

   (low,a)=SCL_sha512.SHA512(buffer);
    a &= (1 << 254) - 8;
    a |= (1 << 254);

    return a;
 }

}

