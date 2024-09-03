/********************************************************************************************/
/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License                                        
/* 
/********************************************************************************************/
/* This file implements elliptic curve over short weierstrass form, with coefficient a=-3, with xyzz coordinates */
/* It is a custom 4 dimensional version of Shamir's trick (tis not a window)*/
/* (gen= any curve, sw=short weierstrass) */
/* b4=Four dimensional multiexponentiation */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import {_ModExpError} from "../include/SCL_errcodes.sol";

//Starting from mload(0x40) this is the mapping in allocated memory
//https://medium.com/@ac1d_eth/technical-exploration-of-inline-assembly-in-solidity-b7d2b0b2bda8
//mapping from 0x40 in memory
uint256 constant __Prec_T8=0x800;
uint256 constant __Ap=0x820;
uint256 constant __y2=0x840;
uint256 constant ___zzz2=0x860;//temporary address for zzz2
uint256 constant __free=0x880;

//mapping from Q in input to function, contains Qx, Qy, p, a, gx, gy
//where P' is P multiplied by 2 pow 128 for shamir's multidimensional trick
//todo: remove all magic numbers
uint constant __Qx=0x00;
uint constant __Qy=0x20;
uint constant __modp=0x40;
uint constant __a=0x60;
uint constant __gx=0x80;
uint constant __gy=0xa0;




//this function is for use only after validation of the Q input:
//Q shall belongs to the curve, and different from -P, -P128, -(P+P128), ...
//those 16 values are tested by the ValidateKey function
//due to handling of Neutral element, this function will not work for 16 specific weak keys
//those value are excluded from the 
function ecGenMulmuladdB4W(
        uint256 [6] memory Q,//store Qx, Qy,  p, a, gx, gy, 
        uint256 scalar_u,
        uint256 scalar_v
    )   view returns (uint256 X, uint Y) {
        uint256 mask=1<<255;
        /* I. precomputations phase */
      

        if(scalar_u==0&&scalar_v==0){
            return (0,0);
        }
     
        uint256 ZZZ;
        uint256 ZZ;
     
       // bytes memory Mem = new bytes(16*4*32);
        assembly ("memory-safe") {
        
         mstore(0x40, add(mload(0x40), __Prec_T8))
         mstore(add(mload(0x40), __Ap), mload(add(Q, __modp)))  //load modulus into AP addresse 

          //store 4 256 bits values starting from addr+offset
       
          /* I. precomputations */
          //allocate memory for 15 projective points, first slot is unused
          {
           let _modulusp:=mload(add(mload(0x40), __Ap))   

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

         function ecDbl(x, y, zz, zzz, _p,a) -> _x, _y, _zz, _zzz{
            let T1 := mulmod(2, y, _p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, _p) // V=U^2
                let T3 := mulmod(x, T2, _p) // S = X1*V
                T1 := mulmod(T1, T2, _p) // W=UV
                _y:= addmod(mulmod(3, mulmod(x,x,_p),_p),mulmod(a,mulmod(zz,zz,_p),_p),_p)//M=3*X12+aZZ12  
                
                _zzz := mulmod(T1, zzz, _p) //zzz3=W*zzz1
                _zz := mulmod(T2, zz, _p) //zz3=V*ZZ1
                
                _x := addmod(mulmod(_y, _y, _p), mulmod(sub(_p,2), T3, _p), _p) //X3=M^2-2S
                T2 := mulmod(_y, addmod(_x, sub(_p, T3), _p), _p) //-M(S-X3)=M(X3-S)

                _y := addmod(mulmod(T1, y, _p), T2, _p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                _y:= sub(_p, _y)
         }


         //normalized addition of two point, must not be neutral input 
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

          mstore4(mload(0x40), 128, mload(add(Q,__gx)), mload(add(Q,__gy)), 1, 1)    //G the base point [1]
          X, Y, ZZ, ZZZ:=ecDbl(mload(add(Q,__gx)), mload(add(Q,__gy)), 1, 1, _modulusp, mload(add(Q,__a)))
          mstore4(mload(0x40), 256, X, Y, ZZ, ZZZ)//2G  [2]
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ, mload(add(Q,__gx)), mload(add(Q,__gy)), _modulusp)//3G
          mstore4(mload(0x40), 384, X, Y, ZZ, ZZZ)//3G  [3]
          mstore4(mload(0x40), 512, mload(add(Q,__Qx)), mload(add(Q,__Qy)), 1, 1)//Q  the public key [4]
          X:=mload(add(Q,__gx))
          Y:= mload(add(Q,__gy))
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y, 1, 1,  mload(add(Q,__Qx)), mload(add(Q,__Qy)),_modulusp)
          mstore4(mload(0x40), 640, X, Y, ZZ, ZZZ)  //G+Q  [5]
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__gx)), mload(add(Q,__gy)),_modulusp)
          mstore4(mload(0x40), 768, X, Y, ZZ, ZZZ) //2G+Q  [6]
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__gx)), mload(add(Q,__gy)),_modulusp)
          mstore4(mload(0x40), 896, X, Y, ZZ, ZZZ)  //3G+Q  [7]
     
          X:=mload(add(Q,__Qx))
          Y:= mload(add(Q,__Qy))
          X, Y, ZZ, ZZZ:=ecDbl(X,Y, 1, 1, _modulusp, mload(add(Q,__a)))//2Q [8]
          mstore4(mload(0x40), 1024, X, Y, ZZ, ZZZ)  //2Q
        
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__gx)), mload(add(Q,__gy)),_modulusp)
          mstore4(mload(0x40), 1152, X, Y, ZZ, ZZZ)  //G+2Q  //[9]
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__gx)), mload(add(Q,__gy)),_modulusp)
          mstore4(mload(0x40), 1280, X, Y, ZZ, ZZZ)  //2G+2Q  //[10]
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__gx)), mload(add(Q,__gy)),_modulusp)
          mstore4(mload(0x40), 1408, X, Y, ZZ, ZZZ)  //3G+2Q  //[11]
          X:=mload(add(mload(0x40), 1024))//load 2Q 
          Y:=mload(add(mload(0x40), 1056))
          ZZ:=mload(add(mload(0x40), 1088))
          ZZZ:=mload(add(mload(0x40), 1120))
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__Qx)), mload(add(Q,__Qy)),_modulusp)//3Q
          mstore4(mload(0x40), 1536, X, Y, ZZ, ZZZ)  //3Q  //[12]
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__gx)), mload(add(Q,__gy)),_modulusp)
          mstore4(mload(0x40), 1664, X, Y, ZZ, ZZZ)  //3Q+G  //[13]
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__gx)), mload(add(Q,__gy)),_modulusp)
          mstore4(mload(0x40), 1792, X, Y, ZZ, ZZZ)  //3Q+2G  //[14]
          X, Y, ZZ, ZZZ:=ecAddn2(X,Y,ZZ,ZZZ,  mload(add(Q,__gx)), mload(add(Q,__gy)),_modulusp)
          mstore4(mload(0x40), 1920, X, Y, ZZ, ZZZ)  //3Q+3G  //[15]
          }

        /*II. First MSB Window*/
                ZZZ:=0
               
                for {} iszero(ZZZ) { mask := shr(2, mask) }{
                 //ZZZ:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(shr(1, scalar_u), mask))))),
                 //          add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(shr(1, scalar_v), mask))))))
                  ZZZ:=add(add(
                  sub(1,iszero(and(scalar_u, shr(1,mask)))),//p0
                  shl(1,sub(1,iszero(and(scalar_u, mask))))),//p1
                  add(shl(2,sub(1,iszero(and(scalar_v, shr(1,mask))))),//q0
                  shl(3,sub(1,iszero(and(scalar_v, mask)))))//q1
                  )
                }
              /* Accumulation is equal to first MSB window*/    
              X:=mload(add(mload(0x40),shl(7,ZZZ)))//X
              Y:=mload(add(mload(0x40),add(32, shl(7,ZZZ))))//Y
              ZZ:=mload(add(mload(0x40),add(64, shl(7,ZZZ))))//ZZ
              ZZZ:=mload(add(mload(0x40),add(96, shl(7,ZZZ))))//ZZZ


             let Mem:=mload(0x40)
             let _p:=mload(add(Mem, __Ap))
        /*III. Main loop */
            //(X,Y,ZZ,ZZZ)=ec_Dbl(X,Y,ZZ,ZZZ);
            //TODO, replace mul by shifts
                for {} gt(mask, 0) { mask := shr(2, mask) } {
                   

                {      
                //X,Y,ZZ,ZZZ:=ecDblNeg(X,Y,ZZ,ZZZ), not having it inplace increase by 12K the cost of the function
                
                let T1 := mulmod(2, Y, _p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, _p) // V=U^2
                let T3 := mulmod(X, T2, _p) // S = X1*V
                T1 := mulmod(T1, T2, _p) // W=UV
                let T4:=mulmod(mload(add(Q,__a)),mulmod(ZZ,ZZ,_p),_p)//aZZ1^2

                T4 := addmod(mulmod(3, mulmod(X,X,_p),_p),T4,_p)//M=3*X12+aZZ12  
                ZZZ := mulmod(T1, ZZZ, _p) //zzz3=W*zzz1
                ZZ := mulmod(T2, ZZ, _p) //zz3=V*ZZ1

                X:=sub(_p,2)//-2
                X := addmod(mulmod(T4, T4, _p), mulmod(X, T3, _p), _p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(X, sub(_p, T3), _p), _p) //-M(S-X3)=M(X3-S)
                Y := addmod(mulmod(T1, Y, _p), T2, _p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                Y:=sub(_p,Y)
                
                }
                {//inline DblNeg      
                //X,Y,ZZ,ZZZ:=ecDblNeg(X,Y,ZZ,ZZZ), not having it inplace increase by 12K the cost of the function
                
                let T1 := mulmod(2, Y, _p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, _p) // V=U^2
                let T3 := mulmod(X, T2, _p) // S = X1*V
                T1 := mulmod(T1, T2, _p) // W=UV
                let T4:=mulmod(mload(add(Q,__a)),mulmod(ZZ,ZZ,_p),_p)//aZZ1^2

                T4 := addmod(mulmod(3, mulmod(X,X,_p),_p),T4,_p)//M=3*X12+aZZ12  
                ZZZ := mulmod(T1, ZZZ, _p) //zzz3=W*zzz1
                ZZ := mulmod(T2, ZZ, _p) //zz3=V*ZZ1
                X:=sub(_p,2)//-2
                X := addmod(mulmod(T4, T4, _p), mulmod(X, T3, _p), _p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(X, sub(_p, T3), _p), _p) //-M(S-X3)=M(X3-S)
                Y := addmod(mulmod(T1, Y, _p), T2, _p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                //Y:=sub(p,Y)
                
                }

             //   let T4:=shl(128,mask)  
             // let T1:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(scalar_u, T4))))),
              //             add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(T4, scalar_v))))))
               
               let T1:=add(add(
                  sub(1,iszero(and(scalar_u, shr(1,mask)))),//p0
                  shl(1,sub(1,iszero(and(scalar_u, mask))))),//p1
                  add(shl(2,sub(1,iszero(and(scalar_v, shr(1,mask))))),//q0
                  shl(3,sub(1,iszero(and(scalar_v, mask)))))//q1
               )
              if iszero(T1) {
                            Y := sub(_p, Y)
                            continue
              }
              //inlined ec_Add
               T1:=shl(7, T1)//computed value address offset      
               
               let T4:=mload(add(Mem,T1))//X2
               mstore(add(Mem, ___zzz2), mload(add(Mem,add(96,T1))))//ZZZ2
               //accumulation is Neutral, so accumulation becomes Window
              //exception raised by wycheproof/ecdsa_secp256r1_sha256_p1363_test.json EcdsaP1363Verify SHA-256 #58
              if iszero(ZZ) {
                            X := T4//X2
                            Y := mload(add(Mem,add(32,T1)))//Y2
                            ZZ := mload(add(Mem,add(64,T1)))//ZZ2
                            ZZZ := mload(add(Mem,add(96,T1)))//ZZZ2
                            continue
                        }
                
                 mstore(add(Mem,__y2), addmod(mulmod( mload(add(Mem,add(32,T1))), ZZZ, _p), mulmod(Y,mload(add(Mem, ___zzz2)), _p), _p))//R=S2-S1, sub avoided
                 T1:=mload(add(Mem,add(64,T1)))//zz2
                 let T2 := addmod(mulmod(T4, ZZ, _p), sub(_p, mulmod(X,T1,_p)), _p)//P=U2-U1

                        //special case ecAdd(P,P)=EcDbl
                        if iszero(mload(add(Mem,__y2))) {
                            if iszero(T2) {
                                T1 := mulmod(sub(_p,2), Y, _p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, _p) // V=U^2
                                mstore(add(Mem,__y2), mulmod(X, T2, _p)) // S = X1*V

                                T1 := mulmod(T1, T2, _p) // W=UV
                                T4:=mulmod(mload(add(Q,__a)),mulmod(ZZ,ZZ,_p),_p)
                                T4 := addmod(mulmod(3, mulmod(X,X,_p),_p),T4,_p)//M=3*X12+aZZ12   //M

                                ZZZ := mulmod(T1, ZZZ, _p) //zzz3=W*zzz1
                                ZZ := mulmod(T2, ZZ, _p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, _p), mulmod(sub(_p,2), mload(add(Mem, __y2)), _p), _p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(mload(add(Mem, __y2)), sub(_p, X), _p), _p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, _p), _p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }
                  T4 := mulmod(T2, T2, _p) //PP
                  T2 := mulmod(T4, T2, _p) //PPP
                  ZZ := mulmod(mulmod(ZZ, T4,_p), T1 ,_p)//zz3=zz1*zz2*PP
                  T1:= mulmod(X,T1, _p)
                  ZZZ := mulmod(mulmod(ZZZ, T2, _p), mload(add(Mem, ___zzz2)),_p) // zzz3=zzz1*zzz2*PPP
                  X := addmod(addmod(mulmod(mload(add(Mem, __y2)), mload(add(Mem, __y2)), _p), sub(_p, T2), _p), mulmod( T1 ,mulmod(sub(_p,2), T4, _p),_p ), _p)// R2-PPP-2*U1*PP
                  T4 := mulmod(T1, T4, _p)///Q=U1*PP
                  Y := addmod(mulmod(addmod(T4, sub(_p, X), _p), mload(add(Mem, __y2)), _p), mulmod(mulmod(Y,mload(add(Mem, ___zzz2)), _p), T2, _p), _p)// R*(Q-X3)-S1*PPP

               }//endloop   
              
                /* IV. Normalization */
                //(X,)=ec_Normalize(X,Y,ZZ,ZZZ);
                
                mstore(0x40, __free)
                 let T := mload(0x40)
                mstore(add(T, 0x60), ZZZ)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using Memmpile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), sub(_p,2))
                mstore(add(T, 0xa0), _p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) {
                    mstore(0x40, _ModExpError)
                    revert(0x40, 0x20)  }
                    
                Y := mulmod(Y, mload(T), _p)//Y/ZZZ
                ZZ :=mulmod(ZZ, mload(T),_p) //1/z
                ZZ:= mulmod(ZZ,ZZ,_p) //1/zz
                X := mulmod(X, ZZ, _p) //X/zz   
          }//end assembly
    }
    

