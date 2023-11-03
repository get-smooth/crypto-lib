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


//STATUS: NOT INTEGRATED, UNTESTED
/*
#unfortunately precompiles return hash 
def FCL_hackmul(k, G):
  v=27+int(G[1])%2;
  r=G[0];
  s=(r*k)%_256K1_ORDER ; 
  return FCL_ecRecover(0, v,r,s);
*/

import { p, gx, gy, gpow2p128_x, gpow2p128_y, n, pMINUS_2, nMINUS_2, MINUS_1, FIELD_OID } from "@solidity/fields/SCL_secp256r1.sol";
import {_SECP256K1} from "@solidity/include/SCL_mask.h.sol";


function ecmul_oracle(uint256 k, uint256 Gx, uint256 Gy) returns (uint256 h){
  if(FIELD_OID==_SECP256K1){
    uint256 v=27+(Gy&1);
    uint256 r=Gx;
    uint256 s=(mulmod(r,k,n));
    //return ecrecover(0,v,r,s);
  }
  else{
    //TODO

  } 
 
}

/*
v=27+(int(G[1])%2);
  r=G[0];
  hash=(-r*s)%_256K1_ORDER;
  s=(-e*s)%_256K1_ORDER;
  
  return FCL_ecRecover(hash, v,r,s);
*/

function ecmulmuladd_oracle(uint256 s, uint256 Gx, uint256 Gy,  uint256 e, uint256 Qx, uint256 Qy)
{
  if(FIELD_OID==_SECP256K1){
    uint256 v=27+(Gy&1);
    uint256 r=Gx;
    uint256 h=(mulmod(n-r,s,n));
    s=addmod(p-e, 0, n);

    //return ecrecover(h,v,r,s);
  }
else{

    //TODO
  } 
}  