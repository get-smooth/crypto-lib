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

//WIP
function ec_mulmuladdX (   
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v)  view returns (uint256 X){
  bool ret;
    uint256[4] memory input;//set larger allocation for ecAdd
    uint256[3] memory uG;
    uint256[3] memory vQ;
    input[0] = gx;
    input[1] = gx;
    input[2] = scalar_u;

    //I. uG
    assembly {
      ret := staticcall(sub(gas(), 2000), 7, input, 0x80, uG, 0x60)
    // Use "invalid" to make gas estimation work
      switch ret case 0 { invalid() }
    }
    require(ret, "ec_mul bn254 failed");
   
    input[0] = Q0;
    input[1] = Q1;
    input[2] = scalar_v;

    //II. vQ
    assembly {
      ret := staticcall(sub(gas(), 2000), 7, input, 0x80, vQ, 0x60)
    // Use "invalid" to make gas estimation work
      switch ret case 0 { invalid() }
    }
    require(ret, "ec_mul bn254 failed");

    assembly {
      ret := staticcall(sub(gas(), 2000), 6, input, 0xc0, uG, 0x60)
    // Use "invalid" to make gas estimation work
      switch ret case 0 { invalid() }
    }

    require(ret, "ec_add bn254 failed");

    //TBD 0 or 1?
    return uG[0];

}