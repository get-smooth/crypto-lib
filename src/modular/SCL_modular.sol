//********************************************************************************************/
///*
///*     ___                _   _       ___               _         _    _ _    
///*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
///*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
///*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
///*                                         |__/|_|           
///*              
///* Copyright (C) 2022 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
///* License: This software is licensed under MIT License                                        
//********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import{ MODEXP_PRECOMPILE} from "../include/SCL_mask.h.sol";
import { p, gx, gy, n, pMINUS_2, nMINUS_2 } from "../include/SCL_field.h.sol";

import {_ModInvError} from "../include/SCL_errcodes.sol";


    /**
     * /* @dev inversion of u mod m using little Fermat theorem via a^(n-2), use of precompiled
     */
    function ModInv(uint256 u, uint256 m) view returns (uint256 result) {

        uint256 mMINUS_2=m-2;

        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), mMINUS_2)
            mstore(add(pointer, 0xa0), m)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), MODEXP_PRECOMPILE, pointer, 0xc0, pointer, 0x20)) {
                  mstore(0x40, _ModInvError)
                  revert(0x40, 0x20) }
            result := mload(pointer)
        }
    }

    /**
     * /* @dev inversion mod nusing little Fermat theorem via a^(n-2), use of precompiled
     */
    function nModInv(uint256 u) view returns (uint256 result) {
        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), nMINUS_2)
            mstore(add(pointer, 0xa0), n)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), MODEXP_PRECOMPILE, pointer, 0xc0, pointer, 0x20)) {  
                mstore(0x40, _ModInvError)
                revert(0x40, 0x20) } 
            result := mload(pointer)
        }
    }
    
    
    
    

