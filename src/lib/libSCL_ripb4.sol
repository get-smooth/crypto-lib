/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This file implements the ecmulmuladd EIP                                     
/********************************************************************************************/
// SPDX-License-Identifier: MIT


import "@solidity/elliptic/SCL_mulmuladd_fullgen_b4.sol";

library SCL_RIPXXX{

    //todo: add callback
 

    //first function of EIP: compute uP+vQ
    function ecMulMulAdd(uint256 [2] memory Q,
        uint256 scalar_u,
        uint256 scalar_v) external view returns (uint256 X, uint256 Y) {
       // return ecGenMulmuladd(Q, scalar_u, scalar_v);
    }

   //first function of EIP: compute uP+vQ using 2 precomputed points
   function ecMulMulAdd_B4(uint256 [10] memory Q,//store Qx, Qy, Q'x, Q'y p, a, gx, gy, gx2pow128, gy2pow128 
        uint256 scalar_u,
        uint256 scalar_v) external view returns (uint256 X, uint256 Y) {
       // return ecGenMulmuladd(Q, scalar_u, scalar_v);
    }
   

}

