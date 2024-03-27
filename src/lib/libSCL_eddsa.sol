/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This file implements the eddsa verification protocol over secp256r1 as specified by RFC8032.                       
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import "@solidity/hash/SCL_sha512.sol";

import  "@solidity/modular/SCL_ModInv.sol"; 
import "@solidity/modular/SCL_sqrtMod_5mod8.sol";
import "@solidity/fields/SCL_wei25519.sol";

import "@solidity/elliptic/SCL_Isogeny.sol";
import "@solidity/lib/libSCL_ripB4.sol";


//5.1.5.  Key Generation


//the name of the library 
library SCL_EDDSA{
 

 function ecPow128(uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ) public returns(uint256 x128, uint256 y128){
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

 function BasePointMultiply(uint256 scalar) internal returns (uint256[2] memory R) {
    uint256 [10] memory Q=[0,0,0,0, p, a, gx, gy, gpow2p128_x, gpow2p128_y ];////store Qx, Qy, Q'x, Q'y , p, a, gx, gy, gx2pow128, gy2pow128 
    //abusing RIPB4 for base point multiplication
    R=SCL_RIPB4.ecMulMulAdd_B4(Q, scalar, 0);

 }

 function HashSecret(uint256 secret) public pure returns (uint256 expanded){
   uint64[16] memory buffer; 
   
 
   uint256 low;
   uint256 high;

   buffer[0]=uint64((secret>>192)&0xffffffffffffffff);
   buffer[1]=uint64((secret>>128)&0xffffffffffffffff);
   buffer[2]=uint64((secret>>64)&0xffffffffffffffff);
   buffer[3]=uint64(secret&0xffffffffffffffff);

/*
   buffer[0]=uint64((secret)&0xffffffffffffffff);
   buffer[1]=uint64((secret>>64)&0xffffffffffffffff);
   buffer[2]=uint64((secret>>128)&0xffffffffffffffff);
   buffer[3]=uint64((secret>>192)&0xffffffffffffffff);
*/

   buffer[4]=uint64(0x80)<<56;
   buffer[15]=0x100;//length is 256 bits

   (low,high)=SCL_sha512.SHA512(buffer);
    expanded=low;
    
    expanded=SCL_sha512.Swap256(expanded);
  expanded &= (1 << 254) - 8;
   expanded |= (1 << 254);

    return expanded;
 }

 //function exposed for RFC8032 compliance, but SetKey is more efficient (Edwards form)
 function ExpandSecret(uint256 secret) public returns (uint256[2] memory Kpub)
 {
   
   secret=HashSecret(secret);
 
   Kpub=BasePointMultiply(secret);
   (Kpub[0], Kpub[1])=WeierStrass2Edwards(Kpub[0], Kpub[1]);

 }

 //eddsa benefit from the 255 bits to compress the parity of y in msb bit
 function edCompress(uint256[2] memory Kpub) public returns(uint256 KPubC){
  KPubC=Kpub[1] +((Kpub[0]&1)<<255) ;

  return KPubC;
 }
 
  /**
     * @notice Extract  coordinates from compressed coordinates (Edwards form)
     *
     * @param KPubC The compressed  point of Edwards form, most significant bit encoding parity
     * @return x The x-coordinate of the point in affine representation
    */
 function edDecompressX(uint256 KPubC) internal returns (uint256 x){
   uint256 y=KPubC;
   uint256 sign=y>>255;//parity bit is the highest bit of compressed point
   uint256 x2;
   uint256 y2=mulmod(y,y,p);
   
   x2 = mulmod(addmod(y2,pMINUS_1,p) , pModInv( addmod(mulmod(d,y2,p),1,p) ) ,p);
   x=SqrtMod(x2);
   if((x&1)!=sign){
            x=p-x;
   }
   return x;
  }
 
 /*
    function ed_decompress(uint256 y, uint256 sign) internal returns (uint256 x)
    {
        uint256 x2;
        uint256 y2=mulmod(y,y,p);
         x2 = mulmod(addmod(y2,MINUS_1,p) , pModInv( addmod(mulmod(d,y2,p),1,p) ) ,p);
        x=SqrtMod(x2);
        if((x&1)!=sign){
            x=p-x;
        }
    }*/

 function SetKey(uint256 secret) public returns (uint256[5] memory extKpub)
 {
  uint256[2] memory Kpub=ExpandSecret(secret);//Edwards form
  extKpub[0]=Kpub[0];
  extKpub[1]=Kpub[1];
  (extKpub[2], extKpub[3])=ecPow128(Kpub[0], Kpub[1], 1, 1);

  extKpub[4]=edCompress(Kpub);//compressed form as expected to hash input
  //todo: add check on curve here
  return extKpub;
 }

/* reduce a 512 bit number modulo curve order*/
function Red512Modq(uint256[2] memory val) internal view returns (uint256 h)
{

  return addmod(mulmod(val[0],0xffffffffffffffffffffffffffffffec6ef5bf4737dcf70d6ec31748d98951d, 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed)
                ,val[1],0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed);

}

 //input are expressed msb first, as any healthy mind should.
 function Verify(bytes memory msg, uint256 r, uint256 s, uint256[5] memory extKpub) public returns(bool flag){
  
   uint256 A=extKpub[4];
   uint256 k;
   uint64[16] memory tampon;
   
   //todo: add parameters checking
   tampon=SCL_sha512.eddsa_sha512(r,A,msg);
   (S[0], S[1]) = SCL_sha512.SHA512(tampon);
   k= Red512Modq(SCL_sha512.Swap512(S)); //swap then reduce mod q

   uint256 [10] memory Q=[extKpub[0], extKpub[1],extKpub[2], extKpub[3], p, a, gx, gy, gpow2p128_x, gpow2p128_y ];

   //3.  Check the group equation [8][S]B = [8]R + [8][k]A'.  It's sufficient, 
   //but not required, to instead check [S]B = R + [k]A'.
   //SCL tweak equality to substraction to check [S]B - [k]A' = [S]B + [n-k]A' = R 
   S=SCL_RIPB4.ecMulMulAdd_B4(Q, s, n-k);
   
   return(S[0]==r);    

 }

}

