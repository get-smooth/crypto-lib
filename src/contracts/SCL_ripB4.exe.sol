/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This file implements a wrapper for the SCL RIP7212 library.                       
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


/* import ripB4 */
import "@solidity/lib/libSCL_ripB4.sol"; 

contract SCL_ripB4{
 //first function of EIP: compute uP+vQ 
 //todo

 //second function of EIP: compute uP+vQ using 2 precomputed points
   function ecMulMulAdd_B4(uint256 [10] memory Q,//store Qx, Qy, Q128x, Q128y , p, a, Px, Py, P128x, P128y 
        uint256 scalar_u,
        uint256 scalar_v) public view returns (uint256[2] memory R) {
        
        return SCL_RIPB4.ecMulMulAdd_B4(Q, scalar_u, scalar_v);
        
    }


}