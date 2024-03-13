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


import {ecdsa_verify, ecdsa_verifyW, ecdsa_verifyG} from  "@solidity/protocols/SCL_ecdsa_utils.sol"; 
import "@solidity/modular/SCL_modular.sol"; 
import "@solidity/elliptic/SCL_mulmuladd_fullgen_b4.sol";

contract SCL_ecdsa_secp256r1{

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

/* basic shamir's trick */
   function verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) external view returns (bool) {
        return ecdsa_verify(message, r, s , qx,  qy);
    }

/* 4-dimensional multiexponentiation */ 
   function verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy, uint256 q2p128_x, uint256 q2p128_y )
   external
   view returns (bool) {
        return ecdsa_verify(message, r, s , qx,  qy, q2p128_x, q2p128_y);
    }


/*  shamir's trick + windowing*/
   function verifyW(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) external view returns (bool) {
        return ecdsa_verifyW(message, r, s , qx,  qy);
    }


    function verifyG(bytes32 message, uint256 r, uint256 s, uint256[10] memory Qpa, uint256 order)  external view returns (bool) {
        return ecdsa_verifyG(message, r, s ,Qpa, order);
    }

    function verifyG2(bytes32 message, uint256 r, uint256 s, uint256[10] memory Qpa, uint256 order)  external view returns (bool) {
       // check the validity of the signature
        if (r == 0 || r >= order || s == 0 || s >= order) {
            return false;
        }

      // calculate the scalars used for the multiplication of the point
        uint256 sInv = ModInv(s,order ); //note that s cannot be 0 as required
        uint256 scalar_u = mulmod(uint256(message), sInv, order);
        uint256 scalar_v = mulmod(r, sInv, order);
       // uint256[10] memory Qpa=[qx, qy,q2p128_x, q2p128_y ,p, a, gx, gy, gpow2p128_x, gpow2p128_y];

        uint256 x1 = ecGenMulmuladdX_store(Qpa, scalar_u, scalar_v);


        assembly {
            x1 := addmod(x1, sub(order, r), order)
        }

         return x1 == 0;
    }

}
