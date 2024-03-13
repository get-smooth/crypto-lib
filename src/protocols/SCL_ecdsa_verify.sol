/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)                                        
/********************************************************************************************/
// SPDX-License-Identifier: MIT


pragma solidity >=0.8.19 <0.9.0;


import {  gx, gy,  gpow2p128_x, gpow2p128_y,n, p, a  } from "@solidity/include/SCL_field.h.sol"; 
import { nModInv } from "@solidity/modular/SCL_modular.sol"; 
import "@solidity/elliptic/SCL_mulmuladd_fullgen_b4.sol";





    /// @notice Verifies an ECDSA signature on the secp256r1 curve given the message, signature, and public key.
    ///         This function is the only one exposed by the library
    /// @param message The original message that was signed
    /// @param r uint256 The r value of the ECDSA signature.
    /// @param s uint256 The s value of the ECDSA signature.
    /// @param qx The x value of the public key Q used for the signature
    /// @param qy The y value of the public key Q used for the signature
    /// @param q2p128_x The x value of precomputed 2**128.Q
    /// @param q2p128_y The y value of of precomputed 2**128.Q
    /// @return bool True if the signature is valid, false otherwise
    /// @dev Note The public key is assumed to belong to the curve and not neutral, additional weak keys are rejected as described in ecdsa_checkpub
/*
function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy, uint256 q2p128_x, uint256 q2p128_y)
view returns (bool)
{
    // check the validity of the signature
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }

      // calculate the scalars used for the multiplication of the point
        uint256 sInv = nModInv(s); //note that s cannot be 0 as required
        uint256 scalar_u = mulmod(uint256(message), sInv, n);
        uint256 scalar_v = mulmod(r, sInv, n);
        uint256[10] memory Qpa=[qx, qy,q2p128_x, q2p128_y ,p, a, gx, gy, gpow2p128_x, gpow2p128_y];

        uint256 x1 = ecGenMulmuladdX_store(Qpa, scalar_u, scalar_v);


        assembly {
            x1 := addmod(x1, sub(n, r), n)
        }

        return x1 == 0;

}
*/