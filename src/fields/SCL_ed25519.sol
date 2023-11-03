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


// prime field modulus of the ed25519 curve
uint256 constant p = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
// -2 mod(p), used to accelerate inversion and doubling operations by avoiding negation
// the representation of -1 in this field
uint256 constant MINUS_1 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;

uint256 constant MINUS_2 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeb;
// the order of the curve, i.e., the number of points on the curve
uint256 constant n = 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed;
// -2 mod(n), used to speed up inversion operations
uint256 constant MINUS_2MODN = 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3eb;

// address of the ModExp precompiled contract (Arbitrary-precision exponentiation under modulo)
address constant MODEXP_PRECOMPILE = 0x0000000000000000000000000000000000000005;
// address of the ModExp precompiled contract (Arbitrary-precision exponentiation under modulo)
uint256 constant d = 0x52036cee2b6ffe738cc740797779e89800700a4d4141d8ab75eb4dca135978a3;
//2*d mod p
uint256 constant deux_d = 16295367250680780974490674513165176452449235426866156013048779062215315747161;
uint256 constant gx = 0x216936D3CD6E53FEC0A4E231FDD6DC5C692CC7609525A7B2C9562D608F25D51A;
uint256 constant gy = 0x6666666666666666666666666666666666666666666666666666666666666658;
//sqrt of -1
uint256 constant sqrtm1=0x2b8324804fc1df0b2b4d00993dfbd7a72f431806ad2fe478c4ee1b274a0ea0b0;
//P+3 div 8
uint256 constant pp3div8=0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;


uint256 constant FIELD_OID=_ED25519;
