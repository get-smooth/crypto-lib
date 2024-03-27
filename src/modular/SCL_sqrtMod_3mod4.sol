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

/// @notice Calculate one modular square root of a given integer. Assume that p=3 mod 4.
/// @dev Uses the ModExp precompiled contract at address 0x05 for fast computation using little Fermat theorem
/// @param self The integer of which to find the modular inverse
/// @return result The modular inverse of the input integer. If the modular inverse doesn't exist, it revert the tx

import{_ERR_NOTSQUARE} from "@solidity/include/SCL_errcodes.h.sol";

import { p, pp1div4, n, pMINUS_2, nMINUS_2, MINUS_1, _MODEXP_PRECOMPILE } from "@solidity/include/SCL_field.h.sol";


function SqrtMod_3mod4(uint256 self)  view returns (uint256 result){
 assembly ("memory-safe") {
        // load the free memory pointer value
        let pointer := mload(0x40)

        // Define length of base (Bsize)
        mstore(pointer, 0x20)
        // Define the exponent size (Esize)
        mstore(add(pointer, 0x20), 0x20)
        // Define the modulus size (Msize)
        mstore(add(pointer, 0x40), 0x20)
        // Define variables base (B)
        mstore(add(pointer, 0x60), self)
        // Define the exponent (E)
        mstore(add(pointer, 0x80), pp1div4)
        // We save the point of the last argument, it will be override by the result
        // of the precompile call in order to avoid paying for the memory expansion properly
        let _result := add(pointer, 0xa0)
        // Define the modulus (M)
        mstore(_result, p)

        // Call the precompiled ModExp (0x05) https://www.evm.codes/precompiled#0x05
        if iszero(
            staticcall(
                not(0), // amount of gas to send
                _MODEXP_PRECOMPILE, // target
                pointer, // argsOffset
                0xc0, // argsSize (6 * 32 bytes)
                _result, // retOffset (we override M to avoid paying for the memory expansion)
                0x20 // retSize (32 bytes)
            )
        ) { revert(0, 0) }

  result := mload(_result)
//  result :=addmod(result,0,p)
 }
   if(mulmod(result,result,p)!=self){
     result=_ERR_NOTSQUARE;
   }
  
   return result;
}
