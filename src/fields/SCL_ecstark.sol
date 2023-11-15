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


import {_STARKCURVE} from "@solidity/include/SCL_mask.h.sol";

/*
stark_p=2^251+17*2^192+1     
stark_a=1;
stark_b=0x6f21413efbe40de150e596d72f7a8c5609ad26c15c915c1f4cdfcb99cee9e89;
stark_q=0x800000000000010ffffffffffffffffb781126dcae7b2321e66a241adc64d2f;
stark_gx = 0x1ef15c18599971b7beced415a40f0c7deacfd9b0d1819e03d723d8bc943cfca;
stark_gy = 0x5668060aa49730b7be4801df46ec62de53ecd11abe43a32873000c36e8dc1f;	
stark_n=0x800000000000010ffffffffffffffffb781126dcae7b2321e66a241adc64d2f;
*/

//2^251+17*2^192+1  
uint256 constant p=  3618502788666131213697322783095070105623107215331596699973092056135872020481;
//curve order
uint256 constant n= 0x800000000000010ffffffffffffffffb781126dcae7b2321e66a241adc64d2f;
uint256 constant a=1;
uint256 constant b=0x6f21413efbe40de150e596d72f7a8c5609ad26c15c915c1f4cdfcb99cee9e89;

uint256 constant  gx=0x1ef15c18599971b7beced415a40f0c7deacfd9b0d1819e03d723d8bc943cfca;
uint256 constant  gy=0x5668060aa49730b7be4801df46ec62de53ecd11abe43a32873000c36e8dc1f;

