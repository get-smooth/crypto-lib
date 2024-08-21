/********************************************************************************************/
/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* License: This software is licensed under MIT License (and allways will)   
#/* Description: Testing contract for SCL implementation of rip7696         
#/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;




import "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
/* import rip7212 */

import { ModInv } from "@solidity/modular/SCL_modular.sol"; 
import "@solidity/lib/libSCL_RIP7696.sol";
  
uint constant _NBTEST=1000;
// prime field modulus of the ed25519 curve
uint256 constant modp = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

// short weierstrass first coefficient 
uint256 constant curvea = 19298681539552699237261830834781317975544997444273427339909597334573241639236;
uint256 constant gx=0x2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad245a;
uint256 constant gy=0x20ae19a1b8a086b4e01edd2c7748d14c923d4d7e6d7c61b229e9c5a27eced3d9;
//0x1ba7c7ff0d602e0108a3dd49027e624914307ae10b22d566e567558e115f578f
uint256 constant gpow2p128_x =12508890695284219941432954705462464418216687521194464129735840385450754660239;
//0x55c7f0494056ac055fdb19191577ef9b2055b5b165e04291aaf7187e6519f779
uint256 constant gpow2p128_y =38799853089443519372474884917849014410429794312182895329810583938938235910009;

contract Test_exeSCL_rip7696 is Test {

 function ecPow128(uint256 p, uint256 a, uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ) public
  view returns(uint256 x128, uint256 y128){
   assembly{
  function ecDbl(x, y, zz, zzz, _p,_a) -> _x, _y, _zz, _zzz{
            let T1 := mulmod(2, y, _p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, _p) // V=U^2
                let T3 := mulmod(x, T2, _p) // S = X1*V
                T1 := mulmod(T1, T2, _p) // W=UV
                _y:= addmod(mulmod(3, mulmod(x,x,_p),_p),mulmod(_a,mulmod(zz,zz,_p),_p),_p)//M=3*X12+aZZ12  
                
                _zzz := mulmod(T1, zzz, _p) //zzz3=W*zzz1
                _zz := mulmod(T2, zz, _p) //zz3=V*ZZ1
                
                _x := addmod(mulmod(_y, _y, _p), mulmod(sub(_p,2), T3, _p), _p) //X3=M^2-2S
                T2 := mulmod(_y, addmod(_x, sub(_p, T3), _p), _p) //-M(S-X3)=M(X3-S)

                _y := addmod(mulmod(T1, y, _p), T2, _p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                _y:= sub(_p, _y)
         }
         for {x128:=0} lt(x128, 128) { x128:=add(x128,1) }{
           X, Y, ZZ, ZZZ := ecDbl(X, Y, ZZ, ZZZ, p, a)
         }
         }
      ZZ=ModInv(ZZ, p);
      ZZZ=ModInv(ZZZ,p);
      x128=mulmod(X, ZZ, p);
      y128=mulmod(Y, ZZZ, p);
    }

  function testbench_ecmulmuladd_wei25519() public view{
      
   
      uint256 qx=0x4fb8c5a7687974c19939eb3f50e9e0a94c76d25fcf8c59a94ce45c4ef748cbec;
      uint256 qy=0x2a7b2162daf8cb019bc2e11f38c9bee54262899f70dfe11bd5b1ecbed34c64ac;
      uint256 u=0xff7b2162daf8cb019bc2e11f38c9bee54262899f70dfe11bd5b1ecbed34c64ff;
      uint256 v=0xff7b2162daf8cb019ff2e11f38c9bee54262899f70dfe11bd5b1ecbed34c64ff;
      uint256  qpow2p128_x;
      uint256 qpow2p128_y;
      (qpow2p128_x, qpow2p128_y)=ecPow128(modp,curvea,qx,qy,1,1);

      uint256 [10] memory Q=[qx,qy,qpow2p128_x, qpow2p128_y, modp,curvea,gx,gy, gpow2p128_x, gpow2p128_y] ;
      for(uint i=0;i<_NBTEST;i++){
        SCL_RIP7696.ecMulMulAdd_B4_xonly(Q, u, v )  ;
        }
  }
}