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


import "forge-std/Test.sol";

import { p, gx, gy } from "@solidity/fields/SCL_ed25519.sol";
import {ec_Normalize, ec_Add, ec_Scaling, ec_Unscaling, ecAff_isOnCurve} from "@solidity/elliptic/SCL_am1ted.sol";


contract SCL_ed25519Test is Test {

function test_OnCurve() public{
  bool res=ecAff_isOnCurve(gx,gy);

  console.log("gx = %x,gy=%x", gx, gy);

  assertEq(res,true);
}

function test_Add() public 
{
    uint256 x;
    uint256 y;
    uint256 z;
    uint256 t;
    uint256 x4;
    uint256 y4;
    uint256 z4;
    uint256 t4;
    uint256 minus_gx = p - gx; //-gy
    uint256 mt;

        (x, y, z, t) = ec_Add(gx, gy, 1, mulmod(gx, gy, p), gx, gy, 1, mulmod(gx, gy, p));

        for (uint256 i = 1; i < 100; i++) {
            (x, y, z, t) = ec_Add(x, y, z, t, x, y, z, t); //P=2P
            minus_gx = p - x;
            mt = mulmod(minus_gx, y, p);
            (x4, y4, z4, t4) = ec_Add(x, y, z, t, x, y, z, t); //2P
            (x4, y4, z4, t4) = ec_Add(x, y, z, t, x, y, z, t); //4P

            (x4, y4, z4, t4) = ec_Add(x4, y4, z4, t4, minus_gx, y, z, mt); //4G-G=3P

            (x4, y4, z4, t4) = ec_Add(x4, y4, z4, t4, minus_gx, y, z, mt); //4G-G=2P

            (x4, y4, z4, t4) = ec_Add(x4, y4, z4, t4, minus_gx, y, z, mt); //4G-G=P
        }

        (x, y) =  ec_Normalize(x4, y4, z4, t4);

       // (x4, y4) =  ec_Normalize(x4, y4, z4, t4);
       // assertEq(x4, x);
    
}


 function test_ed25519() public {
    test_OnCurve();
 }
}
