/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)  
/* Description : point decompression                                      
/********************************************************************************************/
// SPDX-License-Identifier: MIT


    /// @notice Decompress a point given its Px coordinate and parityPy parity
    /// @param p the prime field modulus
    /// @param a the first weierstrass coefficient
    /// @param b the second weierstrass coefficient
    /// @param Px The x value of point
    /// @param parityPy The y value of point
    /// @dev Note The public key is assumed to belong to the curve and not neutral, additional weak keys are rejected 

import "@solidity/modular/SCL_sqrtMod_3mod4.sol";

function ecDecompress(uint256 p, uint256 a, uint256 b, uint256 Px, uint256 parityPy) 
view returns (uint256 y)
{
  // check the validity of the range related to prime field characteristic
         if (Px == 0 || Px >= p || parityPy >1) {
            revert();
        }
 // check the curve equation
       
        uint256 RHS = addmod(mulmod(mulmod(Px, Px, p), Px, p), mulmod(Px, a, p), p); // x^3+ax
        uint256 y2 = addmod(RHS, b, p); // x^3 + a*x + b

        y=SqrtMod(y2);
        if((y&1)!=parityPy){
            y=p-y;
        }

        return y;
}
