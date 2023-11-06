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

import {_SECP256R1} from "@solidity/include/SCL_mask.h.sol";

// prime field modulus of the secp256r1 curve
uint256 constant p = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
// short weierstrass first coefficient
uint256 constant a = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
// short weierstrass second coefficient
uint256 constant b = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
// the affine coordinates of the generating point on the curve
uint256 constant gx = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
uint256 constant gy = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
// the order of the curve, i.e., the number of points on the curve
uint256 constant n = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;

/*//////////////////////////////////////////////////////////////
                            CONSTANTS
//////////////////////////////////////////////////////////////*/

// -2 mod(p), used to accelerate inversion and doubling operations by avoiding negation
uint256 constant pMINUS_2 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFD;
// -2 mod(n), used to speed up inversion operations
uint256 constant nMINUS_2 = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC63254F;
// the representation of -1 in this field
uint256 constant MINUS_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

//precomputed 2^128.G
uint256 constant gpow2p128_x = 30978927491535595270285342502287618780579786685182435011955893029189825707397;
uint256 constant gpow2p128_y= 20481551163499472379222416201371726725754635744576161296521936142531318405938;
uint256 constant _HIBIT_CURVE=255;
uint256 constant FIELD_OID=_SECP256R1;
 //P+1 div 4, used for sqrtmod computation
 uint256 constant pp1div4=0x3fffffffc0000000400000000000000000000000400000000000000000000000;
uint256 constant   _MODEXP_PRECOMPILE=0x05;