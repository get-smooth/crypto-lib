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
/* 
/********************************************************************************************/
/* ec_mulmuladdX wrappers for altbn128 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import {p, gx, gy} from "@solidity/fields/SCL_altbn128.sol";

    // Function for making a call to bn256Add (address 0x06) precompile
    function ec_altbn128_Add(
        uint256 X1, uint256 Y1,
        uint256 X2, uint256 Y2
    )  view returns (uint256 X3, uint256 Y3) {
        uint256[2] memory r;
        assembly {
            // Free memory pointer
            let fp := mload(0x40)
            mstore(fp, mload(X1))
            mstore(add(fp, 0x20),Y1)
            mstore(add(fp, 0x40), X2)
            mstore(add(fp, 0x60), Y2)
            pop(staticcall(gas(), 0x06, fp, 0x80, r, 0x40))
        }


        return (r[0], r[1]);
    }

    // Function for making a call to bn256ScalarMul (address 0x07) precompile
    function ec_altbn128_Mul(
        uint256 Px, uint256 Py,
        uint256 k 
    )  view returns (uint256 kPx, uint256 kPy) {
        uint256[2] memory kP;
        assembly {
            let fp := mload(0x40)
            mstore(fp, Px)
            mstore(add(fp, 0x20), Py)
            mstore(add(fp, 0x40), k)
            pop(staticcall(gas(), 0x07, fp, 0x60, kP, 0x40))
        }
        return (kP[0], kP[1]);
    }
    

//WIP
function ec_mulmuladdX (   
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v)  view returns (uint256 X){

  uint256 Y;
  uint256 X2;
  uint256 Y2;

  (X,Y)=ec_altbn128_Mul(gx, gy, scalar_u);
  (X2,Y2)=ec_altbn128_Mul(Q0, Q1, scalar_v);

  (X,Y)=ec_altbn128_Add(X,Y,X2, Y2);

  return X;
}