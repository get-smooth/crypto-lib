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
/* It is a simple Shamir's trick from old legacy FCL with inlined code*/
/* (am3->a=-3, sw=short weierstrass) */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import {_MASK128, _HI_SCALAR} from "@solidity/include/SCL_mask.h.sol";
import{gpow2p128_x, gpow2p128_y} from "@solidity/include/SCL_field.h.sol"; 
import {ec_mulmuladdX} from  "@solidity/include/SCL_ecmulmuladd.h.sol"; 


    /**
     * @dev Computation of uG+vQ using Strauss-Shamir's trick, G basepoint, Q public key
     *       Returns only x for ECDSA use            
     *      */
   //TODO: test  
   function ec_scalarmulX_basepoint(uint256 scalar) returns(uint256 x, uint256 y){

    ec_mulmuladdX(gpow2p128_x, gpow2p128_y, scalar&_MASK128, scalar>> _HI_SCALAR );

   }
