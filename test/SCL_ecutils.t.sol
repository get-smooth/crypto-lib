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


import { p, gpow2p128_x, gpow2p128_y, a,b ,gx, gy, n, pMINUS_2, nMINUS_2, MINUS_1 } from "@solidity/include/SCL_field.h.sol";
import {_HIBIT_CURVE} from "@solidity/include/SCL_field.h.sol";
import {ec_Add, ec_Aff_Add, ec_AddN, ec_Dbl, ec_Normalize} from "@solidity/include/SCL_elliptic.h.sol";
import "@solidity/elliptic/SCL_ecutils.sol";



contract SCL_secputils is Test {


 function  test_ecPow2mul() public{
    uint256 X;
    uint256 Y;
    
    //test 2 pow 128
    (X,Y)=ec_scalarPow2mul(128, gx, gy, 1, 1);
    assertEq(gpow2p128_x, X);
    assertEq(gpow2p128_y, Y);
    
    //test 2 pow 256, TBD

 }

 function  test_ecAff_isOnCurve() public {
    assertEq(ecAff_isOnCurve(gx,gy), true);/* testing base point is on curve*/
    assertEq(ecAff_isOnCurve(gpow2p128_x,gpow2p128_y), true);
 }

 
 function test_ec_scalarmulN() public { 
   uint256 X;
   uint256 Y;

   //(n+1).G == G ?
   (X,Y)=ec_scalarmulN(n+1, gx, gy);
   assertEq(X, gx);
   assertEq(Y, gy);


 }

 //TODO
 function test_ec_Coronize() public { 

 }

}