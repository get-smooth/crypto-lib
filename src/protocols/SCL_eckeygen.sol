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

import {p,n, gx, gy} from "@solidity/include/SCL_field.h.sol";
import {ec_scalarmulN} from "@solidity/include/SCL_elliptic.h.sol";

/* x-only keygen, compatible with BIP340 */
function ec_KeyGenX(uint256 random)
view returns(uint256 kpriv, uint256 X, uint256 Y)
{
  random=addmod(0,random,n);//ensure random is in [0..n[

  (X,Y)=ec_scalarmulN(random, gx, gy);
   if((Y&1)!=0){
    kpriv=n-random;
    Y=n-Y;
   }  
   else{
    kpriv=random;
   }

  return(kpriv, X, Y);
}

