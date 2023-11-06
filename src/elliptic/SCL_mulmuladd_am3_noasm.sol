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
pragma solidity >=0.8.19 <0.9.0;

import{gx, gy, p, pMINUS_2, MINUS_1, n} from "@solidity/include/SCL_field.h.sol"; 
import { ec_Aff_Add } from "@solidity/include/SCL_elliptic.h.sol";

//TODO