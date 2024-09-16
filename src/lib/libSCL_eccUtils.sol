/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: This library contains utils that provides OFFCHAIN computations, they are  provided as
/* an helper for integration, test and fuzzing BUT SHALL NOT USED ONCHAIN for performances and security reasons                  
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import {ec_isOnCurve} from "../elliptic/SCL_ecOncurve.sol";
import { ModInv } from "@solidity/modular/SCL_modular.sol"; 


library SCL_ECCUTILS{

  
 function ecNormalize(uint256 p, uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ) public
  view returns(uint256 x, uint256 y)
  {
    uint256 ZZZm1= ModInv(ZZZ,p);
    y=mulmod(Y,ZZZm1,p);
    ZZZm1=mulmod(ZZ,ZZZm1,p);//1/z
    ZZZm1=mulmod(ZZZm1, ZZZm1, p);//1/z^2
    x=mulmod(X, ZZZm1, p);

  }

  function ecAddn(uint256 p,uint256 X1,uint256 Y1, uint256 X2, uint256 Y2 ) public view returns (uint256 X, uint256 Y){
        
          assembly{
         function ecAddn2(x1, y1, zz1, zzz1, x2, y2, _p) -> _x, _y, _zz, _zzz {
                y1 := sub(_p, y1)
                y2 := addmod(mulmod(y2, zzz1, _p), y1, _p)
                x2 := addmod(mulmod(x2, zz1, _p), sub(_p, x1), _p)
                _x := mulmod(x2, x2, _p) //PP = P^2
                _y := mulmod(_x, x2, _p) //PPP = P*PP
                _zz := mulmod(zz1, _x, _p) ////ZZ3 = ZZ1*PP
                _zzz := mulmod(zzz1, _y, _p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, _x, _p) //Q = X1*PP
                _x := addmod(addmod(mulmod(y2, y2, _p), sub(_p, _y), _p), mulmod(sub(_p,2), zz1, _p), _p) //R^2-PPP-2*Q

                x1:=mulmod(addmod(zz1, sub(_p, _x), _p), y2, _p)//necessary split not to explose stack
                _y := addmod(x1, mulmod(y1, _y, _p), _p) //R*(Q-X3)
           }
            X,Y,X1,Y1:=ecAddn2(X1,Y1,1,1,X2, Y2, p)
          }

      return ecNormalize(p,X,Y,X1,Y1);
  }         

 function EcDbl(uint256 p, uint256 a, uint256 X, uint256 Y) public view returns (uint256 dX, uint256 dY) {
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

         dX,dY,X,Y:=ecDbl(X,Y,1,1,p,a)
         
  }
    return ecNormalize(p,dX,dY,X,Y);
 }


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

/// @notice Verifies the input parameters of RIP7696 ie curve equations and weak keys
 //test helper to precompute P**128 and Q**128    
function SetKey(uint256 p, uint256 a,uint256 b, uint256 gx, uint256 gy, uint256 qx, uint256 qy) public
  view returns (bool status, uint256[10] memory ExtendedKey  ){
  uint256[10] memory Qpa=[qx,qy,0,0 ,p, a, gx, gy, 0, 0];
  uint256 x;
  uint256 y;
  uint256 G2x;
  uint256 G2y;

  status=true;
  
  //test that provided points are on curve and not infinity
  if(ec_isOnCurve(p,a,b,gx,gy)!=true) return (false, Qpa);
  if(ec_isOnCurve(p,a,b,qx,qy)!=true) return (false, Qpa);
  
  //banned weak keys, according to CRX report, section 2.3
  if(qx==gx) status=false;//Q=+-G is always banned

  //I. Weak keys for the windowing RIP7212 method
  //reject 2G and -2G as valid public keys
  (G2x,G2y)=EcDbl(p,a,gx,gy);
  if(G2x==qx) status=false;
  //reject 3G and -3G
  (Qpa[8], Qpa[9])=ecAddn(p,G2x,G2y,gx,gy);//store 3G
  if(Qpa[8]==qx) status=false;//reject 3G==Q and 3G==-Q 

  //reject 1/2G and -1/2G as valid public keys
  (Qpa[2], Qpa[3])=EcDbl(p,a,qx,qy);//2Q
  if(Qpa[2]==gx) status=false;//reject 2Q=G and 2Q=-G
  if(Qpa[2]==Qpa[8]) status=false;//2Q=+-3G
  
  (x,y)=ecAddn(p,Qpa[2], Qpa[3],qx,qy);//reject 3Q=G and -3Q=G
  if(x==gx) status=false;
  if(x==G2x) status=false;//reject 3Q=2G and -3Q=2G
  
 
  (Qpa[2], Qpa[3])=ecPow128(p, a, qx,qy,1,1);//2**128Q
  (Qpa[8], Qpa[9])=ecPow128(p, a, gx,gy,1,1);//2**128G
  
  //II. Weak keys for the 4MSM RIP7696 method
  if(Qpa[8]==qx) status=false;//reject Q=+-2**128G
  if(Qpa[2]==gx) status=false;//reject G=+-2**128Q
  (x,y)=ecAddn(p, gx, gy, Qpa[8], Qpa[9]);//(1+2**128)G
  if(x==qx) status=false;//reject Q=+-(1+2**128)G
  
  (x,y)=ecAddn(p, gx, gy, Qpa[2], Qpa[3]);//(1+2**128)Q
  if(x==gx) status=false;//reject Q=+-1/(1+2**128)G
  if(x==Qpa[8]) status=false;//reject Q=+(2**128/(1+2**128))G

  G2y= p-Qpa[9];
  (G2x,G2y)=ecAddn(p, gx, gy, Qpa[8],G2y);//(1-2**128)G
  if(G2x==qx) status=false;//reject Q=(1-2**128)G
  if(G2x==x) status=false;//reject Q=((1-2**128)/(1+2**128)G

  
  G2y= p-Qpa[3];
  (G2x,G2y)=ecAddn(p, gx, gy, Qpa[2],G2y );//(1-2**128)Q
  if(G2x==qx) status=false;//reject Q=(1-2**128)G
  if(G2x==x) status=false;//reject Q=((1-2**128)/(1+2**128)G

  return (status, Qpa);
 }
}
    
