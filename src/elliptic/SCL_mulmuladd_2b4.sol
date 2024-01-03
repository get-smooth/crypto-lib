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
/* This file implements elliptic curve over short weierstrass form, with coefficient a=-3, with xyzz coordinates */
/* It is a custom 4 dimensional version of Shamir's trick (tis not a window)*/
/* (am3->a=-3, sw=short weierstrass) */
/* b4=Four dimensional multiexponentiation */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { p, gx, gy, n, pMINUS_2, nMINUS_2, MINUS_1, gpow2p128_x,gpow2p128_y} from "@solidity/include/SCL_field.h.sol";
import {ec_scalarPow2mul, ec_Add, ec_AddN, ec_Dbl, ec_Normalize} from "@solidity/include/SCL_elliptic.h.sol";

//Qx, Qy the public key, scale the number of power of two multiples

function KeyExpansion(uint256 Qx, uint256 Qy, uint scale) view returns (bytes memory KeyExp) {
  uint256 basis_size=1;//first element is base point itself
  uint256 X=Qx; 
  uint256 Y=Qy;
  //store base point
  

  for(uint i=0;i<p;i=i<<scale){
    basis_size++;
  }

  bytes memory temp=new bytes(64*basis_size);
  assembly{
        mstore(add(temp,add(32,mul(64,1))), X)
        mstore(add(temp,add(64,mul(64,1))),Y)
        
      }
  for(uint i=2;i<basis_size;i++){
      (X,Y)=ec_scalarPow2mul(scale, X, Y, 1, 1);
      assembly{
        mstore(add(temp,add(32,mul(64,i))), X)
        mstore(add(temp,add(64,mul(64,i))),Y)
        
      }
  }

  return temp;
}
