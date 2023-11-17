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



import { p, gx, gy, n, pMINUS_2, nMINUS_2 } from "@solidity/include/SCL_field.h.sol"; 
import { nModInv } from "@solidity/modular/SCL_modular.sol"; 
import {ec_mulmuladdX, ec_mulmuladd_S8_extcode} from  "@solidity/include/SCL_ecmulmuladd.h.sol"; 


import {Schnorr_verify} from  "@solidity/protocols/SCL_schnorr.sol"; 


contract SCL_schnorr_stark{


/* basic shamir's trick */
   function verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) external view returns (bool) {
        return Schnorr_verify(message, r, s , qx,  qy);
    }



}