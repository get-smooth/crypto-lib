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

import { _2pow256modn, delta, A, c, a,b,d, p,n, gx, gy, gpow2p128_x, gpow2p128_y, pMINUS_1} from "../fields/SCL_wei25519.sol";
import "../modular/SCL_sqrtMod_5mod8.sol";


//import modular inversion over prime field defined over curve subgroup of prime order
import { ModInv } from "../modular/SCL_modular.sol"; 
//import point on curve checking
import {ec_isOnCurve} from "../elliptic/SCL_ecOncurve.sol";
//import point double multiplication and accumulation (RIP7696)
import "../elliptic/SCL_mulmuladdX_fullgenW.sol";

import "../../external/sha512/Sha2Ext.sol";
import "../hash/SCL_sha512.sol";

library SCL_EIP6565{

 function ecPow128(uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ) public view returns(uint256 x128, uint256 y128){
   assembly{
   function vecDbl(x, y, zz, zzz) -> _x, _y, _zz, _zzz{
            let T1 := mulmod(2, y, p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, p) // V=U^2
                let T3 := mulmod(x, T2, p) // S = X1*V
                T1 := mulmod(T1, T2, p) // W=UV
                let T4 := addmod(mulmod(3, mulmod(x,x,p),p),mulmod(a,mulmod(zz,zz,p),p),p)//M=3*X12+aZZ12  
                _zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                _zz := mulmod(T2, zz, p) //zz3=V*ZZ1

                _x := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(_x, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                _y := addmod(mulmod(T1, y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                _y:= sub(p, _y)
         }
         for {x128:=0} lt(x128, 128) { x128:=add(x128,1) }{
           X, Y, ZZ, ZZZ := vecDbl(X, Y, ZZ, ZZZ)
         }
         }
      ZZ=ModInv(ZZ, p);
      ZZZ=ModInv(ZZZ,p);
      x128=mulmod(X, ZZ, p);
      y128=mulmod(Y, ZZZ, p);
}
 


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
   // uint256[6] memory Q=[gpow2p128_x,gpow2p128_y,p,a,gx,gy];
  uint256[6] memory Q=[gx,gy,p,a,gpow2p128_x,gpow2p128_y];
 
    //abusing RIP7696 first opcode for base point multiplication
    (x,y)=ecGenMulmuladdB4W(Q, 0, scalar);
    return WeierStrass2Edwards(x,y);

 }


function SHA512_modq(bytes memory m) internal pure returns (uint256 h)
{
 bytes32 high;
 bytes32 low;
 (high, low)=Sha2Ext.sha512(m);
 uint256[2] memory S=[uint256(high), uint256(low)];
 h= Red512Modq(SCL_sha512.Swap512(S)); //swap then reduce mod q

 return h;
}

/* reduce a 512 bit number modulo curve order, val being interpreted as the number val[0]<<256+val*/
function Red512Modq(uint256[2] memory val) internal pure returns (uint256 h)
{

  return addmod(mulmod(val[0],_2pow256modn, n),val[1],n);

}

 //eddsa benefit from the 255 bits to compress the parity of y in msb bit
 function edCompress(uint256[2] memory Kpub) public pure returns(uint256 KPubC){
  KPubC=Kpub[1] +((Kpub[0]&1)<<255) ;

  return KPubC;
 }
 
 

//compute h(r,a,m)
 function  HashInternal(uint256 r, uint256 KpubC, string memory m) public pure returns (uint256 k)
 {
  /*
  bytes32 high;
  bytes32 low;
  (high, low)=Sha2Ext.sha512(abi.encodePacked(r,KpubC, m));
  uint256[2] memory S=[uint256(high), uint256(low)];
  k= Red512Modq(SCL_sha512.Swap512(S)); //swap then reduce mod q
  */
  return  SHA512_modq(abi.encodePacked(r,KpubC, m));
 }

 //input are expressed msb first, as any healthy mind should.
 function Verify(string memory m, uint256 r, uint256 s, uint256[5] memory extKpub) 
 public view returns(bool flag){
    uint256 [2] memory S;
   uint256 KpubC=extKpub[4];
   
    // check the value ranges of signature
    if ( s == 0 || s >= n) {
            return false;
    }

   r=SCL_sha512.Swap256(r);

   uint256 k=HashInternal(r, KpubC, m);

   uint256[6] memory Q=[extKpub[0], extKpub[1],p,a,gx,gy];
 
   
   //uint256 [10] memory Q=[extKpub[0], extKpub[1],extKpub[2], extKpub[3], p, a, gx, gy, gpow2p128_x, gpow2p128_y ];
  (S[0], S[1])=ecGenMulmuladdB4W(Q, s, n-k);
  (S[0], S[1])=WeierStrass2Edwards(S[0], S[1]);//back to edwards form
   uint256 recomputed_r=edCompress(S);

   //3.  Check the group equation [8][S]B = [8]R + [8][k]A'.  It's sufficient, 
   //but not required, to instead check [S]B = R + [k]A'.
   //SCL tweak equality to substraction to check [S]B - [k]A' = [S]B + [n-k]A' = R 
   
  
   recomputed_r=SCL_sha512.Swap256(recomputed_r);
   flag=(recomputed_r==r);    

 }

 //input are expressed lsb, require one extra swap compared to msb representation
 function Verify_LE(string memory m, uint256 r, uint256 s, uint256[5] memory extKpub) 
 public view returns(bool flag){
    uint256 [2] memory S;
   uint256 KpubC=extKpub[4];
   
   s=SCL_sha512.Swap256(s);

   // check the value ranges of signature
    if ( s == 0 || s >= n) {
            return false;
    }

   uint256 k=HashInternal(r, KpubC, m);

   uint256[6] memory Q=[extKpub[0], extKpub[1],p,a,gx,gy];
 
   
   //uint256 [10] memory Q=[extKpub[0], extKpub[1],extKpub[2], extKpub[3], p, a, gx, gy, gpow2p128_x, gpow2p128_y ];
  (S[0], S[1])=ecGenMulmuladdB4W(Q, s, n-k);
  (S[0], S[1])=WeierStrass2Edwards(S[0], S[1]);//back to edwards form
   uint256 recomputed_r=edCompress(S);

   //3.  Check the group equation [8][S]B = [8]R + [8][k]A'.  It's sufficient, 
   //but not required, to instead check [S]B = R + [k]A'.
   //SCL tweak equality to substraction to check [S]B - [k]A' = [S]B + [n-k]A' = R 
   
   recomputed_r=SCL_sha512.Swap256(recomputed_r);
   flag=(recomputed_r==r);    

 }

 

}