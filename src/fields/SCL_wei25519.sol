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


// prime field modulus of the ed25519 curve
uint256 constant p = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
// -2 mod(p), used to accelerate inversion and doubling operations by avoiding negation
// the representation of -1 in this field
uint256 constant pMINUS_1 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
uint256 constant pMINUS_2 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeb;

// short weierstrass first coefficient a=-3
uint256 constant a = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffea;
// short weierstrass second coefficient
uint256 constant b =29689592517550930188872794512874050362622433571298029721775200646451501277098;
uint256 constant gx=53837179229940872434942723257480777370451127212339198133697207846219400243292;
uint256 constant gy=6954807309110018441440205552927997039251486742285514177307080418460388229929;


