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

 /// @notice Verifies the input parameters of RIP7696, second opcode. ie curve equations and weak keys
 //test helper to precompute P**128 and Q**128
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
    
function SetKey(uint256 p, uint256 a,uint256 b, uint256 gx, uint256 gy, uint256 qx, uint256 qy) public
  view returns (bool status, uint256[10] memory ExtendedKey  ){
  uint256[10] memory Qpa=[qx,qy,0,0 ,p, a, gx, gy, 0, 0];

  bool status=true;
  
  //test that provided points are on curve
  if(ec_isOnCurve(p,a,b,gx,gy)!=true) return (false, Qpa);
  if(ec_isOnCurve(p,a,b,qx,qy)!=true) return (false, Qpa);
  
  (Qpa[2], Qpa[3])=ecPow128(p, a, qx,qy,1,1);
  (Qpa[8], Qpa[9])=ecPow128(p, a, gx,gy,1,1);
  
  status=ecCheckPrecompute(Qpa);

  return (status, Qpa);
}

//mapping from Q in input to function, contains Qx, Qy, Qx', Qy', p, a, gx, gy, gx', gy'
//where P' is P multiplied by 2 pow 128 for shamir's multidimensional trick
//todo: remove all magic numbers
uint constant _Qx=0x00;
uint constant _Qy=0x20;
uint constant _Qx2pow128=0x40;
uint constant _Qy2pow128=0x60;
uint constant _modp=0x80;
uint constant _a=0xa0;
uint constant _gx=0xc0;
uint constant _gy=0xe0;
uint constant _gpow2p128_x=0x100;
uint constant _gpow2p128_y=0x120;

//Starting from mload(0x40) this is the mapping in allocated memory
//https://medium.com/@ac1d_eth/technical-exploration-of-inline-assembly-in-solidity-b7d2b0b2bda8
//mapping from 0x40 in memory
uint256 constant _Prec_T8=0x800;
uint256 constant _Ap=0x820;
uint256 constant _y2=0x840;
uint256 constant _zzz2=0x860;
uint256 constant _free=0x880;

// a brutal copy paste of Ecmulmuladd precomputations
function ecCheckPrecompute(
        uint256 [10] memory Q//store Qx, Qy, Q'x, Q'y p, a, gx, gy, gx2pow128, gy2pow128 
    )   public view returns (bool flag) {
        /* I. precomputations phase */

        uint256 X;
        uint256 Y;
        uint256 ZZZ;
        uint256 ZZ;
        flag=false;

       // bytes memory Mem = new bytes(16*4*32);
        assembly ("memory-safe") {
        
         mstore(0x40, add(mload(0x40), _Prec_T8))
         mstore(add(mload(0x40), _Ap), mload(add(Q, 0x80)))  //load modulus into AP addresse 

          //store 4 256 bits values starting from addr+offset
          function mstore4(addr, offset, val1, val2, val3, val4){
             mstore(add(offset, addr),val1 )
             offset:=add(32, offset)
             mstore(add(offset, addr),val2 )
             offset:=add(32, offset)
             mstore(add(offset, addr),val3 )
             offset:=add(32, offset)
             mstore(add(offset, addr),val4 )
             offset:=add(32, offset)
          }
          /* I. precomputations */
          //allocate memory for 15 projective points, first slot is unused
          
           let _modulusp:=mload(add(mload(0x40), _Ap))   
         //normalized addition of two point, must not be neutral input 
         function ecAddn2(x1, y1, zz1, zzz1, x2, y2, _p) -> _x, _y, _zz, _zzz {
                y1 := sub(_p, y1)
                y2 := addmod(mulmod(y2, zzz1, _p), y1, _p)
                x2 := addmod(mulmod(x2, zz1, _p), sub(_p, x1), _p)
                _x := mulmod(x2, x2, _p) //PP = P^2
                _y := mulmod(_x, x2, _p) //PPP = P*PP
                _zz := mulmod(zz1, _x, _p) ////ZZ3 = ZZ1*PP
                if iszero(_zz) {//either P1=P2 or P1=-P2, not allowed
                mstore(0x80, shl(229, 4594637)) 
                 mstore(0x84, 32) 
                mstore(0xA4, 30)
                mstore(0xC4, "Amount to raise smaller than 0")
               revert(0x80, 0x64)
                }
                _zzz := mulmod(zzz1, _y, _p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, _x, _p) //Q = X1*PP
                _x := addmod(addmod(mulmod(y2, y2, _p), sub(_p, _y), _p), mulmod(sub(_p,2), zz1, _p), _p) //R^2-PPP-2*Q

                x1:=mulmod(addmod(zz1, sub(_p, _x), _p), y2, _p)//necessary split not to explose stack
                _y := addmod(x1, mulmod(y1, _y, _p), _p) //R*(Q-X3)
                
              }
           

          mstore4(mload(0x40), 128, mload(add(Q,_gx)), mload(add(Q,_gy)), 1, 1)                       //G the base point
          mstore4(mload(0x40), 256, mload(add(Q,_gpow2p128_x)), mload(add(Q,_gpow2p128_y)), 1, 1)     //G'=2^128.G
          
          X:=mload(add(Q,_gpow2p128_x))
          Y:=mload(add(Q,_gpow2p128_y))
          X,Y,ZZ,ZZZ:=ecAddn2( X,Y,1,1, mload(add(Q,_gx)),mload(add(Q,_gy)), _modulusp) //G+G'
          mstore4(mload(0x40), 384, X,Y,ZZ,ZZZ)                        //Q, the public key
          mstore4(mload(0x40), 512, mload(Q),mload(add(32,Q)),1,1)                         
         
          X,Y,ZZ,ZZZ:=ecAddn2( mload(Q),mload(add(Q,32)),1,1, mload(add(Q,_gx)),mload(add(Q,_gy)),_modulusp )//G+Q
          mstore4(mload(0x40), 640, X,Y,ZZ,ZZZ)   
         
          
          X:=mload(add(Q,_gpow2p128_x))
          Y:=mload(add(Q,_gpow2p128_y))
          X,Y,ZZ,ZZZ:=ecAddn2(X,Y,1,1,mload(Q),mload(add(Q,32)), _modulusp)//G'+Q
          mstore4(mload(0x40), 768, X,Y,ZZ,ZZZ)   
        
          X,Y,ZZ,ZZZ:=ecAddn2( X,Y,ZZ,ZZZ, mload(add(Q,_gx)), mload(add(Q,_gy)), _modulusp)//G'+Q+G
          mstore4(mload(0x40), 896, X,Y,ZZ,ZZZ)  
         
          mstore4(mload(0x40), 1024, mload(add(Q, 64)), mload(add(Q, 96)),1,1)   //Q'=2^128.Q


          X,Y,ZZ,ZZZ:=ecAddn2(mload(add(Q, 64)), mload(add(Q, 96)),1,1, mload(add(Q,_gx)),mload(add(Q,_gy)), mload(add(mload(0x40), _Ap))   )//Q'+G
          mstore4(mload(0x40), 1152, X,Y,ZZ,ZZZ)  
        
          
          X:=mload(add(Q,_gpow2p128_x))
          Y:=mload(add(Q,_gpow2p128_y))
          X,Y,ZZ,ZZZ:=ecAddn2(mload(add(Q, 64)), mload(add(Q, 96)),1,1, X,Y, mload(add(mload(0x40), _Ap))   )//Q'+G'
          mstore4(mload(0x40), 1280, X,Y,ZZ,ZZZ)  
           
          X,Y,ZZ,ZZZ:=ecAddn2(X, Y, ZZ, ZZZ, mload(add(Q,_gx)), mload(add(Q,_gy)), mload(add(mload(0x40), _Ap))   )//Q'+G'+G
          mstore4(mload(0x40), 1408, X,Y,ZZ,ZZZ)  
           
          X,Y,ZZ,ZZZ:=ecAddn2( mload(Q),mload(add(Q,32)),1,1, mload(add(Q, 64)), mload(add(Q, 96)), mload(add(mload(0x40), _Ap))   )//Q+Q'
          mstore4(mload(0x40), 1536, X,Y,ZZ,ZZZ)  

          X,Y,ZZ,ZZZ:=ecAddn2( X,Y,ZZ,ZZZ, mload(add(Q,_gx)), mload(add(Q,_gy)), mload(add(mload(0x40), _Ap))   )//Q+Q'+G
          mstore4(mload(0x40), 1664, X,Y,ZZ,ZZZ)  

         X:= mload(add(768, mload(0x40)) )//G'+Q
         Y:= mload(add(800, mload(0x40)) )
         ZZ:= mload(add(832, mload(0x40)) )
         ZZZ:=mload(add(864, mload(0x40)) )
         X,Y,ZZ,ZZZ:=ecAddn2( X,Y,ZZ,ZZZ,mload(add(Q, 64)), mload(add(Q, 96)), mload(add(mload(0x40), _Ap))   )//G'+Q+Q'+
         mstore4(mload(0x40), 1792, X,Y,ZZ,ZZZ)  

          X,Y,ZZ,ZZZ:=ecAddn2( X,Y,ZZ,ZZZ,mload(add(Q,0xc0)),mload(add(Q,_gy)), mload(add(mload(0x40), _Ap))   )//G'+Q+Q'+G
          //  Prec[15]
          mstore4(mload(0x40), 1920, X,Y,ZZ,ZZZ)  
          }
           flag=true;// no revert means no pathologic case were reached
        }
       
    }
    
