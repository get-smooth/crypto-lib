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
import { nModInv } from "@solidity/modular/SCL_modular.sol"; 
import {ecGenMulmuladdW} from  "@solidity/elliptic/SCL_mulmuladd_gen_windowed.sol"; 



  function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) view returns (bool) {
        // check the validity of the signature
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }

        // check the public key is on the curve is done by the caller
        /* if (!ECDSA.affIsOnCurve(qx, qy)) {
            return false;
        }*/

        // calculate the scalars used for the multiplication of the point
        uint256 sInv = nModInv(s);
        uint256 scalar_u = mulmod(uint256(message), sInv, n);
        uint256 scalar_v = mulmod(r, sInv, n);

        uint256 x1 = ecGenMulmuladdW(qx, qy, scalar_u, scalar_v);

        assembly {
            x1 := addmod(x1, sub(n, r), n)
        }

        return x1 == 0;
    }