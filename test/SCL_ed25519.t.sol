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



import {_ED25519} from "@solidity/include/SCL_mask.h.sol";
import {FIELD_OID} from "@solidity/include/SCL_field.h.sol";

import "forge-std/Test.sol";

import { p, gx, gy } from "@solidity/fields/SCL_ed25519.sol";
import {ec_Normalize, ec_Add, ec_Scaling, ec_Unscaling, ecAff_isOnCurve} from "@solidity/elliptic/SCL_am1ted.sol";


contract SCL_ed25519Test is Test {

function t_OnCurve() public{
  bool res=ecAff_isOnCurve(gx,gy);

  console.log("gx = %x,gy=%x", gx, gy);

  assertEq(res,true);
  res=ecAff_isOnCurve(p-gx,gy);
  assertEq(res,true);
 
}

//vectors extracted from https://asecuritysite.com/curve25519/ed
//https://crypto.stackexchange.com/questions/99798/test-vectors-points-for-ed25519
//Point 1G 5866666666666666666666666666666666666666666666666666666666666666 
//Point 2G, x= 0x36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e
//Point 5G x=0x49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233

function t_Add()  public 
{
    uint256 x=gx;
    uint256 y=gy;
    uint256 z=1;
    uint256 t=mulmod(x,y,p);
    
    (x, y) =  ec_Normalize(x,y,z,t);

    (x, y, z, t) = ec_Add(x, y, 1, mulmod(x, y, p), x, y, 1, mulmod(x, y, p));//2G
    (x, y, z, t) = ec_Add(x, y, z, t, x, y, z, t);//4G
    (x, y, z, t) = ec_Add(x, y, z,t, gx, gy, 1, mulmod(gx, gy, p));//5G
    (x, y) =  ec_Normalize(x,y,z,t);
    
    assertEq(x, 0x49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233);
}


 function test_ed25519() public returns(bool){
   console.log("test libSCL_ed25519:");
   if(FIELD_OID!=_ED25519){//desactivate test if configuration is not set to secp256r1
      console.log("untested");
      return true;
   }

    t_OnCurve();
    t_Add();
 }
}
