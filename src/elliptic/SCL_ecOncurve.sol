/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)  
/* Description : testing the validity of an input point                                      
/********************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


    /// @notice Check the validity of a Public keys
    /// @param qx The x value of the public key Q used for the signature
    /// @param qy The y value of the public key Q used for the signature
    /// @dev Note The public key is assumed to belong to the curve and not neutral, additional weak keys are rejected 

function ec_isOnCurve(uint256 p, uint256 a, uint256 b, uint256 qx, uint256 qy) 
pure returns (bool)
{
  // check the validity of the range related to prime field characteristic
         if ( (qx == 0 && qy == 0) || qx >= p  || qy >= p) {
            return false;
        }
 // check the curve equation
        uint256 LHS = mulmod(qy, qy, p); // y^2
        uint256 RHS = addmod(mulmod(mulmod(qx, qx, p), qx, p), mulmod(qx, a, p), p); // x^3+ax
        RHS = addmod(RHS, b, p); // x^3 + a*x + b

        return LHS == RHS;
}
