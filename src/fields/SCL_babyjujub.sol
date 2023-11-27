
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


import {_TODO, _UNUSED,  _BABYJJ} from "@solidity/include/SCL_mask.h.sol";
//reduced twisted edwards form of babyjj , https://github.com/bellesmarta/baby_jubjub

uint256 constant p=21888242871839275222246405745257275088548364400416034343698204186575808495617;
uint256 constant n=21888242871839275222246405745257275088614511777268538073601725287587578984328;
uint256 constant gx=4986949742063700372957640167352107234059678269330781000560194578601267663727;
uint256 constant gy= 5472060717959818805561601436314318772137091100104008585924551046643952123905;
uint256 constant d =12181644023421730124874158521699555681764249180949974110617291017600649128846;
uint256 constant a=21888242871839275222246405745257275088548364400416034343698204186575808495616;

uint256 constant b=_UNUSED;
//2*d mod p 
uint256 constant deux_d = 2475045175004185027501911298141836274980133961483913877536377848625489762075;

uint256 constant pMINUS_2 =21888242871839275222246405745257275088548364400416034343698204186575808495615;
uint256 constant nMINUS_2=21888242871839275222246405745257275088614511777268538073601725287587578984326;

// the representation of -1 over 255 bits
uint256 constant MINUS_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
uint256 constant _HIBIT_CURVE=254;
uint256 constant pp1div4=_UNUSED;
//p=1 mod 8

uint constant gpow2p128_x=_TODO;
uint constant gpow2p128_y=_TODO; 


uint256 constant   _MODEXP_PRECOMPILE=0x05;

uint256 constant FIELD_OID=_BABYJJ;