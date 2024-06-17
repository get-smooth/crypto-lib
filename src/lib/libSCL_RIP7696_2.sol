/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This file implements the ecmulmuladd EIP                                     
/********************************************************************************************/
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

//import point on curve checking
import {ec_isOnCurve} from "@solidity/elliptic/SCL_ecOncurve.sol";

//import Shamir's trick 4 dimensional
import "@solidity/elliptic/SCL_mulmuladdX_fullgen_b4.sol";

//implementation of ecmulmuladd_b4 of RIPXXX
library SCL_RIPB4{


   //second function of EIP: compute uP+vQ using 2 precomputed points
   function ecMulMulAdd_B4(uint256 [10] memory Q,//store Qx, Qy, Q'x, Q'y , p, a, gx, gy, gx2pow128, gy2pow128 
        uint256 scalar_u,
        uint256 scalar_v) internal view returns (uint256[2] memory R) {
        
        R[0]= ecGenMulmuladdX_store(Q, scalar_u, scalar_v);
        
        return R; 
    }

   
     /* default is RIPB4 precompile as described in rip-b4 (name to be changed after submission)*/
     /* expected RIP data is: p, a, b, gx, gy, gx128, gy128, qx128, qy128*/
    function _fallback(bytes calldata input) internal view returns (bytes memory ret) {
        if ((input.length != 384) ) {
            return abi.encodePacked(uint256(0));
        }
        uint256 [10] memory Q;

        Q[4] = uint256(bytes32(input[0:32]));//p
        Q[5] = uint256(bytes32(input[32:64]));//a
        uint256 b = uint256(bytes32(input[64:96]));//b
        Q[6] = uint256(bytes32(input[96:128]));//x
        Q[7] = uint256(bytes32(input[128:160]));//y
        Q[8] = uint256(bytes32(input[160:192]));//x128
        Q[9] = uint256(bytes32(input[192:224]));//x128
        Q[0] = uint256(bytes32(input[224:256]));//qx
        Q[1] = uint256(bytes32(input[256:288]));//qy
        Q[2] = uint256(bytes32(input[288:320]));//qy
        uint256 u = uint256(bytes32(input[320:352]));//u
        uint256 v= uint256(bytes32(input[352:384]));//v
        
        if(ec_isOnCurve(Q[4],Q[5],b, Q[6],Q[7])==false){
         revert();
        }

        if(ec_isOnCurve(Q[4],Q[5],b,Q[0], Q[1])==false){
         revert();
        }

       
        return abi.encodePacked(ecGenMulmuladdX_store(Q, u, v));

        
    }

}

