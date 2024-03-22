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
    /// @dev Note the implementation is currently limited to p=3 mod 4 modulus (secp256r1)

import "@solidity/modular/SCL_sqrtMod_3mod4.sol";

function ecDecompress(uint256 p, uint256 a, uint256 b, uint256 Px, uint256 parityPy) 
view returns (uint256 y)
{
  // check the validity of the range related to prime field characteristic
         if (Px == 0 || Px >= p || parityPy >1) {
            revert();
        }

        //todo implement sqrt mod for generic modulos using tonelly shanks
        if(p&3!=3)
        {
            revert();
        }
       
        uint256 RHS = addmod(mulmod(mulmod(Px, Px, p), Px, p), mulmod(Px, a, p), p); // x^3+ax
        uint256 y2 = addmod(RHS, b, p); // x^3 + a*x + b

        y=SqrtMod(y2);
        if((y&1)!=parityPy){
            y=p-y;
        }

        return y;
}
