/********************************************************************************************/
/*
/*     ___                _   _       ___               _         _    _ _    
/*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
/*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
/*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
/*                                         |__/|_|           
/*              
/* Copyright (C) 2023 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
/* License: This software is licensed under MIT License                                        
/* 
/********************************************************************************************/
/* This file implements elliptic curve over short weierstrass form, with coefficient a=-3, with xyzz coordinates */
/* It is a custom 4 dimensional version of Shamir's trick (tis not a window)*/
/* (am3->a=-3, sw=short weierstrass) */
/* b4=Four dimensional multiexponentiation */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { p, gx, gy, n, pMINUS_2, nMINUS_2, MINUS_1, gpow2p128_x,gpow2p128_y} from "@solidity/include/SCL_field.h.sol";

  
//this function is for use only after validation of the Q input:
//Q shall belongs to the curve, and different from -P, -P128, -(P+P128), ...
//those 16 values are tested by the ValidateKey function
//due to handling of Neutral element, this function will not work for 16 specific weak keys
//those value are excluded from the 
function ec_mulmuladdX_asm(
       /* uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 Q2, 
        uint256 Q3, //affine rep for precomputations*/
        uint256 [4] memory Q,
        uint256 scalar_u,
        uint256 scalar_v
    )   view returns (uint256 X) {
        uint256 mask=1<<127;
        /* I. precomputation phase */

        if(scalar_u==0&&scalar_v==0){
            return 0;
        }
        uint256 Y;
        uint256 ZZZ;
        uint256 ZZ;
        
       
        bytes memory Preco = new bytes(16*4*32);

        assembly{
         let _p:=p
         
    
          /* Utils */
         //normalized addition of two point, must not be neutral input 
         function ecAddn(x1, y1, zz1, zzz1, x2, y2) -> _x, _y, _zz, _zzz {
                y1 := sub(p, y1)
                y2 := addmod(mulmod(y2, zzz1, p), y1, p)
                x2 := addmod(mulmod(x2, zz1, p), sub(p, x1), p)
                _x := mulmod(x2, x2, p) //PP = P^2
                _y := mulmod(_x, x2, p) //PPP = P*PP
                _zz := mulmod(zz1, _x, p) ////ZZ3 = ZZ1*PP
                _zzz := mulmod(zzz1, _y, p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, _x, p) //Q = X1*PP
                _x := addmod(addmod(mulmod(y2, y2, p), sub(p, _y), p), mulmod(pMINUS_2, zz1, p), p) //R^2-PPP-2*Q
                _y := addmod(mulmod(addmod(zz1, sub(p, _x), p), y2, p), mulmod(y1, _y, p), p) //R*(Q-X3)
           }

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
          /* I. Precomputations */
          //allocate memory for 15 projective points, first slot is unused
          mstore4(Preco, 128, gx, gy, 1, 1)                       //G the base point
          mstore4(Preco, 256, gpow2p128_x, gpow2p128_y, 1, 1)     //G'=2^128.G
          

          X,Y,ZZ,ZZZ:=ecAddn( gpow2p128_x,gpow2p128_y,1,1, gx,gy) //G+G'
          mstore4(Preco, 384, X,Y,ZZ,ZZZ)                        //Q, the public key
          mstore4(Preco, 512, mload(Q),mload(add(32,Q)),1,1)                         
         
          X,Y,ZZ,ZZZ:=ecAddn( mload(Q),mload(add(Q,32)),1,1, gx,gy)//G+Q
          mstore4(Preco, 640, X,Y,ZZ,ZZZ)   
         
          X,Y,ZZ,ZZZ:=ecAddn(gpow2p128_x,gpow2p128_y,1,1,mload(Q),mload(add(Q,32)))//G'+Q
          mstore4(Preco, 768, X,Y,ZZ,ZZZ)   
        
          X,Y,ZZ,ZZZ:=ecAddn( X,Y,ZZ,ZZZ, gx, gy)//G'+Q+G
          mstore4(Preco, 896, X,Y,ZZ,ZZZ)  
         
          mstore4(Preco, 1024, mload(add(Q, 64)), mload(add(Q, 96)),1,1)   //Q'=2^128.Q

          X,Y,ZZ,ZZZ:=ecAddn(mload(add(Q, 64)), mload(add(Q, 96)),1,1, gx,gy)//Q'+G
          mstore4(Preco, 1152, X,Y,ZZ,ZZZ)  
        
          X,Y,ZZ,ZZZ:=ecAddn(mload(add(Q, 64)), mload(add(Q, 96)),1,1, gpow2p128_x,gpow2p128_y)//Q'+G'
          mstore4(Preco, 1280, X,Y,ZZ,ZZZ)  
           
          X,Y,ZZ,ZZZ:=ecAddn(X, Y, ZZ, ZZZ, gx, gy)//Q'+G'+G
          mstore4(Preco, 1408, X,Y,ZZ,ZZZ)  
           
          X,Y,ZZ,ZZZ:=ecAddn( mload(Q),mload(add(Q,32)),1,1, mload(add(Q, 64)), mload(add(Q, 96)))//Q+Q'
          mstore4(Preco, 1536, X,Y,ZZ,ZZZ)  

          X,Y,ZZ,ZZZ:=ecAddn( X,Y,ZZ,ZZZ, gx, gy)//Q+Q'+G
          mstore4(Preco, 1664, X,Y,ZZ,ZZZ)  

         X:= mload(add(768, Preco) )//G'+Q
         Y:= mload(add(800, Preco) )
         ZZ:= mload(add(832, Preco) )
         ZZZ:=mload(add(864, Preco) )
         X,Y,ZZ,ZZZ:=ecAddn( X,Y,ZZ,ZZZ,mload(add(Q, 64)), mload(add(Q, 96)))//G'+Q+Q'+
         mstore4(Preco, 1792, X,Y,ZZ,ZZZ)  

          X,Y,ZZ,ZZZ:=ecAddn( X,Y,ZZ,ZZZ,gx,gy)//G'+Q+Q'+G
          //  Prec[15]
          mstore4(Preco, 1920, X,Y,ZZ,ZZZ)  

        
        /*II. First MSB bit*/
                ZZZ:=0
                for {} iszero(ZZZ) { mask := shr(1, mask) }{
                ZZZ:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(shr(128, scalar_u), mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(shr(128, scalar_v), mask))))))

                }
                
              X:=mload(add(Preco,shl(7,ZZZ)))//X
              Y:=mload(add(Preco,add(32, shl(7,ZZZ))))//X
              ZZ:=mload(add(Preco,add(64, shl(7,ZZZ))))//X
              ZZZ:=mload(add(Preco,add(96, shl(7,ZZZ))))//X


        /*III. Main loop */
            //(X,Y,ZZ,ZZZ)=ec_Dbl(X,Y,ZZ,ZZZ);
            //TODO, replace mul by shifts
                for {} gt(mask, 0) { mask := shr(1, mask) } {

                {    
               
                let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, p) // V=U^2
                let T3 := mulmod(X, T2, p) // S = X1*V
                T1 := mulmod(T1, T2, p) // W=UV
                let T4 := mulmod(3, mulmod(addmod(X, sub(p, ZZ), p), addmod(X, ZZ, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                ZZZ := mulmod(T1, ZZZ, p) //zzz3=W*zzz1
                ZZ := mulmod(T2, ZZ, p) //zz3=V*ZZ1, V free

                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                //Y:=sub(p,Y)
                }
              let T1:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(shr(128, scalar_u), mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(shr(128, scalar_v), mask))))))
                            
              if iszero(T1) {
                            Y := sub(p, Y)
                            continue
              }
              //inlined ec_Add
               T1:=shl(7, T1)//precomputed value address offset      
               
               let T4:=mload(add(Preco,T1))//X2
               let zzz2:= mload(add(Preco,add(96,T1)))//ZZZ2
                 
                
                 let y2 := addmod(mulmod( mload(add(Preco,add(32,T1))), ZZZ, p), mulmod(Y,zzz2, p), p)//R=S2-S1, sub avoided
                 T1:=mload(add(Preco,add(64,T1)))//zz2
                 let T2 := addmod(mulmod(T4, ZZ, p), sub(p, mulmod(X,T1,p)), p)//P=U2-U1

                        //special case ecAdd(P,P)=EcDbl
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(pMINUS_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                let T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                              
                               
                                y2 := mulmod(addmod(X, ZZ, p), addmod(X, sub(p, ZZ), p), p) //(X-ZZ)(X+ZZ)
                              
                                T4 := mulmod(3, y2, p) //M

                                ZZZ := mulmod(T1, ZZZ, p) //zzz3=W*zzz1
                                ZZ := mulmod(T2, ZZ, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }
                  T4 := mulmod(T2, T2, p) //PP
                  T2 := mulmod(T4, T2, p) //PPP
                  ZZ := mulmod(mulmod(ZZ, T4, p), T1 ,p)//zz3=zz1*zz2*PP
                  T1:= mulmod(X,T1, p)
                  ZZZ := mulmod(mulmod(ZZZ, T2, p), zzz2,p) // zzz3=zzz1*zzz2*PPP
                  X := addmod(addmod(mulmod(y2, y2, p), sub(p, T2), p), mulmod( T1 ,mulmod(pMINUS_2, T4, p),p ), p)// R2-PPP-2*U1*PP
                  T4 := mulmod(T1, T4, p)///Q=U1*PP
                  Y := addmod(mulmod(addmod(T4, sub(p, X), p), y2, p), mulmod(mulmod(Y,zzz2, p), T2, p), p)// R*(Q-X3)-S1*PPP

               }//endloop   
                /* IV. Normalization */
                //(X,)=ec_Normalize(X,Y,ZZ,ZZZ);
                 let T := mload(0x40)
                mstore(add(T, 0x60), ZZ)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), pMINUS_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                //Y:=mulmod(Y,zzz,p)//Y/zzz
                //zz :=mulmod(zz, mload(T),p) //1/z
                //zz:= mulmod(zz,zz,p) //1/zz
                X := mulmod(X, mload(T), p) //X/zz   
          }//end assembly
    }
    

