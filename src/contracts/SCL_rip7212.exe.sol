/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This file implements a wrapper for the SCL RIP7212 library.                       
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


/* import rip7212 */
import  "@solidity/lib/libSCL_rip7212.sol"; 

contract SCL_rip7212{

     /* default is EIP7212 precompile as described in https://eips.ethereum.org/EIPS/eip-7212*/
    fallback(bytes calldata input) external returns (bytes memory ret) {
        if ((input.length != 160) ) {
            return abi.encodePacked(uint256(0));
        }

        bytes32 message = bytes32(input[0:32]);
        uint256 r = uint256(bytes32(input[32:64]));
        uint256 s = uint256(bytes32(input[64:96]));
        uint256 Qx = uint256(bytes32(input[96:128]));
        uint256 Qy = uint256(bytes32(input[128:160]));
        /* no precomputations */
        if (input.length == 160) {
            return abi.encodePacked(verify(message, r, s, Qx, Qy));
        }

        /* with precomputations written at address prec (previously generated using ecdsa_precalc_8dim*/
        
    }

   function verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) public view returns (bool) {
        return SCL_RIP7212.verify(message, r, s , qx,  qy);
    }


}