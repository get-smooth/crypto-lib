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

// SPDX-License-Identifier: MIT

//https://emn178.github.io/online-tools/sha512.html

pragma solidity >=0.8.19 <0.9.0;

import "../../external/sha512/Sha2Ext.sol";

library SCL_sha512 {
 
    function Swap512(uint256[2] memory w) internal pure returns(uint256[2] memory r)
    {
        r[0]=Swap256(w[1]);
        r[1]=Swap256(w[0]);

        return r;
    }

    function Swap256(uint256 w) internal pure returns (uint256 x)
    {
        return uint256(Swap128(uint128(w>>128)))^(uint256(Swap128(uint128(w&0xffffffffffffffffffffffffffffffff)))<<128);
    }

    function Swap128(uint128 w) internal pure returns (uint128 x)
    {
        return uint128(Swap64(uint64(w>>64)))^(uint128(Swap64(uint64(w&0xffffffffffffffff)))<<64);
    }


    function Swap64(uint64 w) internal pure returns (uint64 x){
     uint64 tmp= (w >> 32) | (w << 32);
	 tmp = ((tmp & 0xff00ff00ff00ff00) >> 8) |    ((tmp & 0x00ff00ff00ff00ff) << 8); 
	 x = ((tmp & 0xffff0000ffff0000) >> 16) |   ((tmp & 0x0000ffff0000ffff) << 16); 
    }

}