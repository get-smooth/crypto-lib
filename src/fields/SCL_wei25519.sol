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

// short weierstrass first coefficient 
uint256 constant a = 19298681539552699237261830834781317975544997444273427339909597334573241639236;
// short weierstrass second coefficient 0x41a3b6bfc668778ebe2954a4b1df36d1485ecef1ea614295796e102240891faa
uint256 constant b =55751746669818908907645289078257140818241103727901012315294400837956729358436;
uint256 constant n = 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed;
uint256 constant nMINUS_2 = 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3eb;

uint256 constant gx=0x2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad245a;
uint256 constant gy=0x20ae19a1b8a086b4e01edd2c7748d14c923d4d7e6d7c61b229e9c5a27eced3d9;



