//********************************************************************************************/
///*
///*     ___                _   _       ___               _         _    _ _    
///*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
///*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
///*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
///*                                         |__/|_|           
///*              
///* Copyright (C) 2023 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
///* License: This software is licensed under MIT License                                        
//********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

// prime field modulus of the ed25519 curve
uint256 constant _MASK128 = 0xffffffffffffffffffffffffffffffff;
uint256 constant _HI_SCALAR=128;
uint256 constant _HIBIT_CURVE=255;

// prime field modulus of the secp256r1 curve
uint256 constant MODEXP_PRECOMPILE=0x05;

/* curves are identified by their OID */
uint256 constant _SECP256R1=0x06082A648CE3D030107;
uint256 constant _ED25519=  0x060a2b060104019755010501;
uint256 constant _SECP256K1=0x06052B8104000A;

