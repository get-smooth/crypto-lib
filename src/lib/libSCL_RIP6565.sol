/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)      
/* Description: This file implements the ecdsa verification protocol using Shamir's trick + 4bit windowing.                                        
/********************************************************************************************/
// SPDX-License-Identifier: MIT
//As specified by Rene Struik in
//https://datatracker.ietf.org/doc/draft-ietf-lwig-curve-representations/


pragma solidity >=0.8.19 <0.9.0;

import { delta, A, c, a,b,p, gx, gy, gpow2p128_x, gpow2p128_y} from "../fields/SCL_wei25519.sol";

//import modular inversion over prime field defined over curve subgroup of prime order
import { ModInv } from "../modular/SCL_modular.sol"; 
//import point on curve checking
import {ec_isOnCurve} from "../elliptic/SCL_ecOncurve.sol";
//import point double multiplication and accumulation (RIP7696)
import "../elliptic/SCL_mulmuladdX_fullgenW.sol";



library SCL_RIP6565{


function Edwards2WeierStrass(uint256 x,uint256 y)  internal view returns (uint256 X, uint256 Y){
  //wx = ((1 + ey) * (1 - ey)^-1) + delta
  X=addmod(delta, mulmod(addmod(1,y,p),ModInv(addmod(1, p-y,p),p),p) ,p);
  //  wy = (c * (1 + ey)) * ((1 - ey) * ex)^-1
  
  Y=mulmod(mulmod(c, addmod(1, y, p),p),        ModInv(mulmod(addmod(1, p-y,p), x,p),p),p);
}

// ex  = (c * pa) * (3 * my)^-1 (mod p)

function WeierStrass2Edwards(uint256 X,uint256 Y)  internal view returns (uint256 x, uint256 y){
     // pa  = 3 * wx - A
     // ex  = (c * pa) * (3 * wy)^-1 (mod p)
    //  ey = (pa - 3) * (pa + 3)^-1 (mod p)
    uint pa=addmod(mulmod(3,X, p), p-A,p);
    uint inv=ModInv(mulmod(3,Y,p),p);
    x=mulmod(mulmod(c,pa,p), inv,p);
    inv=ModInv(addmod(pa,3,p),p);
  
  //  ey = (pa - 3) * (pa + 3)^-1 (mod p)
    y=mulmod(addmod(pa, p-3, p), inv, p);

}

 
 function BasePointMultiply(uint256 scalar) public view returns (uint256 x, uint256 y) {
    uint256[6] memory Q=[gpow2p128_x,gpow2p128_y,p,a,gx,gy];
 
    //abusing RIP7696 first opcode for base point multiplication
    (x,y)=ecGenMulmuladdB4W(Q, scalar, 0);
    return WeierStrass2Edwards(x,y);


   //uint256[10] memory Qpa= [gx,gy,gpow2p128_x, gpow2p128_y, p,a,gx,gy, gpow2p128_x, gpow2p128_y];//store Qx, Qy, Q'x, Q'y p, a, gx, gy, gx2pow128, gy2pow128 
   //x=ecGenMulmuladdX_store(Qpa, scalar, 0);
    //return WeierStrass2Edwards(x,y);

 }


}