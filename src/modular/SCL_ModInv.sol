/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This file implements basic operations on elliptic curve                       
/********************************************************************************************/
// SPDX-License-Identifier: MIT


import{ MODEXP_PRECOMPILE} from "@solidity/include/SCL_mask.h.sol";

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
            if iszero(staticcall(not(0), MODEXP_PRECOMPILE, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            result := mload(pointer)
        }
    }