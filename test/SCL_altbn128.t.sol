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

import "@solidity/elliptic/SCL_atlbn128.sol";

//scroll, optim, starkcurve et edhackaton

contract SCL_altbn128Test is Test {

 function test_Fuzz_mulmuladd() public view returns(bool)
 {
    uint256 scalar=p-7;

    uint256 gmy=p-gy;
    uint256[2] memory res;
    uint256[2] memory PointX=[gx,gy];

  //  res=ec_mulmuladdX(gx, gmy, scalar+1, scalar);
    (res[0],res[1])=ec_altbn128_Mul(gx, gy, uint256(3));

    console.log("******res ecmul", res[0]);

    return true;
 }

 function SCL_altbn128() public view returns (bool){
   bool res=true;
  
   res=res && test_Fuzz_mulmuladd();
 
   return res;
 }


}