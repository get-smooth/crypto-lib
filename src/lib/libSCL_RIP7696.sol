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


//import point double multiplication and accumulation (RIP7696), first operator
import "@solidity/elliptic/SCL_mulmuladdX_fullgenW.sol";

//import Shamir's trick 4 dimensional, second operator
import "@solidity/elliptic/SCL_mulmuladdX_fullgen_b4.sol";


library SCL_RIP7696{


    /* first operator of precompile 7696 */
     /* expected RIP data is: p, a, b, gx, gy, gx128, gy128, qx, qy, qx128, qy128*/
    function ecMulmuladd(uint256 [8] memory input) internal view returns (uint256[2] memory R) 
    {

        uint256 [6] memory Q;

        Q[2] = input[0];//p
        Q[3] = input[1];//a
        uint256 b = input[2];//b
        Q[4] = input[3];//gx
        Q[5] = input[4];//gy
        Q[0] = input[5];//qx
        Q[1] = input[6];//qy
     
        //assert pub key is on curve
        if(ec_isOnCurve(Q[2],Q[3],b,Q[0], Q[1])==false){
         revert();
        }

        //assert base point is on curve
        if(ec_isOnCurve(Q[2],Q[3],b, Q[4],Q[5])==false){
         revert();
        }

        uint256 u = input[6];//u
        uint256 v= input[7];//v
        (R[0], R[1])= ecGenMulmuladdB4W(Q, u, v);
        
        return R; 
    }

  
    /* second operator of precompile 7696 */
     /* expected RIP data is: p, a, b, gx, gy, gx128, gy128, qx, qy, qx128, qy128*/
    function ecMulmuladdB4(uint256 [13] memory input) internal view returns (uint256[2] memory R) 
    {

        uint256 [10] memory Q;

        Q[4] = input[0];//p
        Q[5] = input[1];//a
        uint256 b = input[2];//b
        Q[6] = input[3];//gx
        Q[7] = input[4];//gy
        Q[8] = input[5];//gx128
        Q[9] = input[6];//gy128
        Q[0] = input[7];//qx
        Q[1] = input[8];//qy
        Q[2] = input[9];//qx128
        Q[3] = input[10];//qy128

        if(ec_isOnCurve(Q[4],Q[5],b,Q[0], Q[1])==false){
         revert();
        }
        if(ec_isOnCurve(Q[4],Q[5],b, Q[6],Q[7])==false){
         revert();
        }

        uint256 u = input[11];//u
        uint256 v= input[12];//v
        R[0]= ecGenMulmuladdX_store(Q, u, v);
        
        return R; 
    }

     /* default is precompile as described in rip7686 */
     /* expected RIP data is: p, a, b, gx, gy, gx128, gy128, qx, qy, qx128, qy128*/
    function _fallback(bytes calldata input) internal view returns (bytes memory ret) {
        if ((input.length != 416) ) {
            return abi.encodePacked(uint256(0));
        }
        uint256 [10] memory Q;

        Q[4] = uint256(bytes32(input[0:32]));//p
        Q[5] = uint256(bytes32(input[32:64]));//a
        uint256 b = uint256(bytes32(input[64:96]));//b
        Q[6] = uint256(bytes32(input[96:128]));//gx
        Q[7] = uint256(bytes32(input[128:160]));//gy
        Q[8] = uint256(bytes32(input[160:192]));//gx128
        Q[9] = uint256(bytes32(input[192:224]));//gy128
        Q[0] = uint256(bytes32(input[224:256]));//qx
        Q[1] = uint256(bytes32(input[256:288]));//qy
        Q[2] = uint256(bytes32(input[288:320]));//qx128
        Q[3] = uint256(bytes32(input[320:352]));//qy128
        
        uint256 u = uint256(bytes32(input[352:384]));//u
        uint256 v= uint256(bytes32(input[384:416]));//v
        
        if(ec_isOnCurve(Q[4],Q[5],b, Q[6],Q[7])==false){
         revert();
        }

        if(ec_isOnCurve(Q[4],Q[5],b,Q[0], Q[1])==false){
         revert();
        }

       
        return abi.encodePacked(ecGenMulmuladdX_store(Q, u, v));
    }

   //internal call, no curve testing, ordering optimized for performances, return only x value (sufficient in most use high level cases)
   function ecMulMulAdd_B4_xonly(uint256 [10] memory Q,//store Qx, Qy, Q'x, Q'y , p, a, gx, gy, gx2pow128, gy2pow128 
        uint256 scalar_u,
        uint256 scalar_v) internal view returns (uint256[2] memory R) {
        
        R[0]= ecGenMulmuladdX_store(Q, scalar_u, scalar_v);
        
        return R; 
    }

}

