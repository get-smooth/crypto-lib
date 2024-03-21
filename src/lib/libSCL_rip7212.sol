/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This file implements the ecdsa verification protocol over secp256r1 as specified by RIP7212.                       
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

/* import ecdsa verification using Shamir's trick+windowing */
import {ecdsa_verify} from "@solidity/protocols/SCL_ecdsaW.sol"; 

library SCL_RIP7212{
  /* default is EIP7212 precompile as described in https://eips.ethereum.org/EIPS/eip-7212*/
    function _fallback(bytes calldata input) internal returns (bytes memory ret) {
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

   function verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) internal view returns (bool) {
        return ecdsa_verify(message, r, s , qx,  qy);
    }
}