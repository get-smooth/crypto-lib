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

import { p, gx, gy, n, pMINUS_2, nMINUS_2 } from "@solidity/include/SCL_field.h.sol"; 
import "@solidity/modular/SCL_modular.sol"; 
import {ecAff_isOnCurve} from "@solidity/include/SCL_elliptic.h.sol";

import {ec_mulmuladdX, ec_mulmuladd_S8_extcode, ecGenMulmuladdW} from  "@solidity/include/SCL_ecmulmuladd.h.sol"; 
import {ecdsa_verify, ecdsa_sign, ecdsa_verifyW, ecdsa_verifyG} from  "@solidity/protocols/SCL_ecdsa_utils.sol"; 
import "@solidity/elliptic/SCL_mulmuladd_fullgen_b4.sol";


contract SCL_secp256r1_utils{
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
            return abi.encodePacked(ecdsa_verify(message, r, s, Qx, Qy));
        }

        /* with precomputations written at address prec (previously generated using ecdsa_precalc_8dim*/
        
    }

   function verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) external view returns (bool) {
        return ecdsa_verify(message, r, s , qx,  qy);
    }

    function sign(bytes32 message, uint256 k , uint256 kpriv) external view returns(uint256 r, uint256 s)
    {
       return ecdsa_sign(message,k, kpriv);
    }

    function isOnCurve(uint256 x, uint256 y) external pure returns (bool){

        return ecAff_isOnCurve(x,y);
    }


   function verifyW(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) external view returns (bool) {
        return ecdsa_verifyW(message, r, s , qx,  qy);
    }

    function verifyG(bytes32 message, uint256 r, uint256 s, uint256[10] memory Qpa, uint256 order)  external view returns (bool) {
        return ecdsa_verifyG(message, r, s ,Qpa, order);
    }



}
