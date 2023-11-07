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


import{_ZERO_U256} from "@solidity/include/SCL_mask.h.sol";
import { p, a, gx, gy, n, pMINUS_2, nMINUS_2, MINUS_1 } from "@solidity/include/SCL_field.h.sol";
import {gpow2p128_x,gpow2p128_y} from "@solidity/include/SCL_field.h.sol";
import {ec_Add, ec_TestEq, ec_AddN, ec_Dbl, ec_Normalize, ecAff_isOnCurve} from "@solidity/include/SCL_elliptic.h.sol";
import{ec_hAdd} from "@solidity/elliptic/SCL_ecutils.sol";
import "@solidity/elliptic/SCL_mulmuladd_am3_b4_noasm.sol";


contract SCL_mulmuladd_b4_prec is Test {
 
 
 function test_ecPrecb4() public returns(bool res){
  res=false;

  uint256 qx=0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c;
  uint256 qy=0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032;
  uint256 q2p128_x=112495727131302244506157669471790202209849926651017016481532073180322115017576;
  uint256 q2p128_y=88228053145992414849958298035823172674083888062809552550982514976029750463913;
  uint256 x;
  uint256 y;
   uint256 zz; uint256 zzz;

  uint256[4][16] memory Prec= ec_MultiplierPrec([qx,qy,q2p128_x, q2p128_y]);

  //assert each precomputed point belongs to the curve
  for(uint256 i=1;i<16;i++){
    (x,y)=ec_Normalize(Prec[i][0], Prec[i][1], Prec[i][2], Prec[i][3]);
    assertEq(true, ecAff_isOnCurve(x,y));
  }
  res=true;


  for(uint256 quadribit=1;quadribit<16;quadribit++){
    (x,y,zz,zzz)=(0,0,0,0);

    if(quadribit&1!=0){
        
    (x,y,zz,zzz)= ec_hAdd(x,y,zz,zzz, Prec[1][0], Prec[1][1], Prec[1][2], Prec[1][3]);
    }
    if(quadribit&2!=0){
    (x,y,zz,zzz)= ec_hAdd(x,y,zz,zzz, Prec[2][0], Prec[2][1], Prec[2][2], Prec[2][3]);
    }
     if(quadribit&4!=0){
    (x,y,zz,zzz)= ec_hAdd(x,y,zz,zzz, Prec[4][0], Prec[4][1], Prec[4][2], Prec[4][3]);
    }
     if(quadribit&8!=0){
    (x,y,zz,zzz)= ec_hAdd(x,y,zz,zzz, Prec[8][0], Prec[8][1], Prec[8][2], Prec[8][3]);
    }
    
    assertEq(true, ec_TestEq(x,y,zz,zzz, Prec[quadribit][0], Prec[quadribit][1], Prec[quadribit][2], Prec[quadribit][3]));

  }

  return res;
 }

 
 function test_b4() public returns (bool){
  

   console.log("mulmul b4:");
   if(a!=p-3){//desactivate test if configuration is not set to secp256r1
      console.log("untested");
      return true;
   }

   bool res= true;
   assertEq(res,true);

   return res;
 }
}

