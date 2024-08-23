/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)      
/* Description: This file implements offchain computation related to secret key management

/* NEVER USE THIS ONCHAIN EXCEPT FOR EXPERIMENTS AND TESTING, SECRET ELEMENTS ARE MEANT TO STAY OFFLINE
/* THIS FILE IS PROVIDED TO ENABLE FUZZING AND TESTING
/********************************************************************************************/
// SPDX-License-Identifier: MIT
//As specified by Rene Struik in
//https://datatracker.ietf.org/doc/draft-ietf-lwig-curve-representations/


pragma solidity >=0.8.19 <0.9.0;

import "@solidity/lib/libSCL_EIP6565.sol";



library SCL_EIP6565_UTILS{

 //to be called offchain, compute both signing secret and extended public key
 function SetKey(uint256 secret) public view returns (uint256[5] memory extKpub, uint256[2] memory signer)
 {
  uint256[2] memory Kpub;
  

   bytes memory input=abi.encodePacked(secret);
   bytes32 high;
   bytes32 low;

   (high, low)=Sha2Ext.sha512(input);
   
   uint256 expanded=SCL_sha512.Swap256(uint256(high));
   expanded &= (1 << 254) - 8;
   expanded |= (1 << 254);
   signer[0]=expanded;
   signer[1]=uint256(low);
  
   (Kpub[0], Kpub[1])=SCL_EIP6565.BasePointMultiply_Edwards(expanded);
   extKpub[4]=SCL_sha512.Swap256(SCL_EIP6565.edCompress(Kpub));//compressed Kpub in edwards form

  (extKpub[0], extKpub[1])=SCL_EIP6565.Edwards2WeierStrass(Kpub[0], Kpub[1]);
  (extKpub[2], extKpub[3])=SCL_EIP6565.ecPow128(extKpub[0], extKpub[1], 1, 1);
 
  //todo: add check on curve here
  return (extKpub, signer);
 }


 //function exposed for RFC8032 compliance (Edwards form), but SetKey is more efficient 
 //(keep Weierstrass compatible with 7696)
 function ExpandSecret(uint256 secret) public view returns (uint256 KpubC,uint256 expanded)
 {
  uint256[2] memory Kpub;

   bytes memory input=abi.encodePacked(secret);
   bytes32 high;
   bytes32 low;

   (high, low)=Sha2Ext.sha512(input);
   
   expanded=SCL_sha512.Swap256(uint256(high));
   expanded &= (1 << 254) - 8;
   expanded |= (1 << 254);

 
   (Kpub[0], Kpub[1])=SCL_EIP6565.BasePointMultiply_Edwards(expanded);
   KpubC=SCL_sha512.Swap256(SCL_EIP6565.edCompress(Kpub));

 }


 //secret signert can be precomputed from the secret seed once for all
 function Sign(uint256 KpubC, uint256[2] memory signer,  string memory m) public view returns(uint256 r, uint256 s)
 {
   uint256[6] memory Q=[0, 0,p,a,gx,gy];
   uint256 [2] memory R; 

   uint256 k=SCL_EIP6565.SHA512_modq(abi.encodePacked(signer[1],m));

   (R[0], R[1])=ecGenMulmuladdB4W(Q, k, 0);//rG
   (R[0], R[1])=SCL_EIP6565.WeierStrass2Edwards(R[0], R[1]);//back to edwards form
   r=SCL_EIP6565.edCompress(R);//returned r part of the signature
   r=SCL_sha512.Swap256(r);

   uint256 h=SCL_EIP6565.HashInternal(r, KpubC, m);

   s=addmod(k, mulmod(h,signer[0],n),n );//s = (k + h * a) % q
   s=SCL_sha512.Swap256(s);

   return(r,s);
 }

 function SignSlow(uint256 secret_seed, string memory m) public view  returns(uint256 r, uint256 s){
   uint256[5] memory extKpub;
   uint256[2] memory signer;
   
   (extKpub, signer)=SetKey(secret_seed);
   
   (r,s)=Sign(extKpub[4], signer, m);

 }
}