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
import "../modular/SCL_sqrtMod_5mod8.sol";


//import modular inversion over prime field defined over curve subgroup of prime order
import { ModInv } from "../modular/SCL_modular.sol"; 
//import point on curve checking
import {ec_isOnCurve} from "../elliptic/SCL_ecOncurve.sol";
//import point double multiplication and accumulation (RIP7696)
import "../elliptic/SCL_mulmuladdX_fullgenW.sol";

import "../../external/sha512/Sha2Ext.sol";
import "../hash/SCL_sha512.sol";

library SCL_RIP6565{



    function Swap64(uint64 w) internal pure returns (uint64 x){
     uint64 tmp= (w >> 32) | (w << 32);
	 tmp = ((tmp & 0xff00ff00ff00ff00) >> 8) |    ((tmp & 0x00ff00ff00ff00ff) << 8); 
	 x = ((tmp & 0xffff0000ffff0000) >> 16) |   ((tmp & 0x0000ffff0000ffff) << 16); 
    }


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
 }

 //todo: speedup by splitting scalars
 function BasePointMultiply_Edwards(uint256 scalar) public view returns (uint256 x, uint256 y) {
    uint256[6] memory Q=[gpow2p128_x,gpow2p128_y,p,a,gx,gy];
 
    //abusing RIP7696 first opcode for base point multiplication
    (x,y)=ecGenMulmuladdB4W(Q, scalar, 0);
    return WeierStrass2Edwards(x,y);


   //uint256[10] memory Qpa= [gx,gy,gpow2p128_x, gpow2p128_y, p,a,gx,gy, gpow2p128_x, gpow2p128_y];//store Qx, Qy, Q'x, Q'y p, a, gx, gy, gx2pow128, gy2pow128 
   //x=ecGenMulmuladdX_store(Qpa, scalar, 0);
    //return WeierStrass2Edwards(x,y);

 }

 
/* reduce a 512 bit number modulo curve order*/
function Red512Modq(uint256[2] memory val) internal pure returns (uint256 h)
{

  return addmod(mulmod(val[0],
  0xffffffffffffffffffffffffffffffec6ef5bf4737dcf70d6ec31748d98951d, 
  0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed)
                ,val[1],0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed);

}

 //eddsa benefit from the 255 bits to compress the parity of y in msb bit
 function edCompress(uint256[2] memory Kpub) public pure returns(uint256 KPubC){
  KPubC=Kpub[1] +((Kpub[0]&1)<<255) ;

  return KPubC;
 }
 
 

 //function exposed for RFC8032 compliance (Edwards form), but SetKey is more efficient 
 //(keep Weierstrass compatible with 7696)
 function ExpandSecret(uint256 secret) public view returns (uint256 KpubC,uint256 expanded)
 {
  uint256[2] memory Kpub;

   bytes memory input=abi.encodePacked(secret);
   bytes32 high;
   bytes32 low;

   (high, low)=Sha2Ext.sha512(input);
   
   expanded=SCL_sha512.Swap256(uint256(high));
   expanded &= (1 << 254) - 8;
   expanded |= (1 << 254);

 
   (Kpub[0], Kpub[1])=BasePointMultiply_Edwards(expanded);
   KpubC=SCL_sha512.Swap256(edCompress(Kpub));//evil Bernstein loves swaps

 }

 
 //input are expressed msb first, as any healthy mind should.
 function Verify(bytes memory msg, uint256 r, uint256 s, uint256[5] memory extKpub) public returns(bool flag){
   uint256 [2] memory S;
   uint256 A=extKpub[4];
   uint256 k;
   uint64[16] memory tampon;
   
   //todo: add parameters checking
   //tampon=SCL_sha512.eddsa_sha512(r,A,msg);
   //(S[0], S[1]) = SCL_sha512.SHA512(tampon);
   //k= SCL_EDDSA.Red512Modq(SCL_sha512.Swap512(S)); //swap then reduce mod q
   
   //uint256 [10] memory Q=[extKpub[0], extKpub[1],extKpub[2], extKpub[3], p, a, gx, gy, gpow2p128_x, gpow2p128_y ];
   
   (S[0], S[1])=WeierStrass2Edwards(extKpub[0], extKpub[1]);
  
   //3.  Check the group equation [8][S]B = [8]R + [8][k]A'.  It's sufficient, 
   //but not required, to instead check [S]B = R + [k]A'.
   //SCL tweak equality to substraction to check [S]B - [k]A' = [S]B + [n-k]A' = R 
   //S=SCL_RIPB4.ecMulMulAdd_B4(Q, s, n-k);
   //(S[0], S[1])=WeierStrass2Edwards(S[0], S[1]);//back to edwards form
   //uint256 recomputed_r=edCompress(S);
   
   //return(recomputed_r==r);    

 }
 
}