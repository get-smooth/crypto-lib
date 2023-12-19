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

  import{_ZERO_U256} from "@solidity/include/SCL_mask.h.sol";
  import { p, gx, gy, n, pMINUS_2, nMINUS_2, MINUS_1 } from "@solidity/include/SCL_field.h.sol";
  import {gpow2p128_x,gpow2p128_y} from "@solidity/include/SCL_field.h.sol";
  import {ec_Add, ec_AddN, ec_Dbl, ec_Normalize} from "@solidity/include/SCL_elliptic.h.sol";


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
        
        /* I. Precomputations */
        //allocate memory for 16 projective points
        bytes memory Preco = new bytes(16*4*32);

        assembly{
          //Prec[1]=[gx,gy,1,1];
          mstore(add(128, Preco),gx )
          mstore(add(160, Preco),gy ) 
          mstore(add(192, Preco),1 )
          mstore(add(224, Preco),1 )
          //Prec[2]=[gpow2p128_x,gpow2p128_y,1,1];
          mstore(add(256, Preco),gpow2p128_x )
          mstore(add(288, Preco),gpow2p128_y ) 
          mstore(add(320, Preco),1 )
          mstore(add(352, Preco),1 )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
         assembly{
          //Prec[3]=ec_AddN_u4( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
          mstore(add(384, Preco),X )
          mstore(add(416, Preco),Y ) 
          mstore(add(448, Preco),ZZ )
          mstore(add(480, Preco),ZZZ )
          //Prec[4]=[Q[0],Q[1],1,1];
          mstore(add(512, Preco),mload(Q) )
          mstore(add(544, Preco),mload(add(32,Q)) ) 
          mstore(add(576, Preco),1 )
          mstore(add(608, Preco),1 )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[0],Q[1],1,1, gx,gy);
        assembly{
          //  Prec[5]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(640, Preco),X )
          mstore(add(672, Preco),Y ) 
          mstore(add(704, Preco),ZZ )
          mstore(add(736, Preco),ZZZ )
        }
       (X,Y,ZZ,ZZZ)=ec_AddN( gpow2p128_x,gpow2p128_y,1,1, Q[0], Q[1]);
        assembly{
          //  Prec[6]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(768, Preco),X )
          mstore(add(800, Preco),Y ) 
          mstore(add(832, Preco),ZZ )
          mstore(add(864, Preco),ZZZ )
        }

       (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ, gx, gy);
        assembly{
          //  Prec[7]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(896, Preco),X )
          mstore(add(928, Preco),Y ) 
          mstore(add(960, Preco),ZZ )
          mstore(add(992, Preco),ZZZ )
          //  Prec[8]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1024, Preco),mload(add(64,Q) ))
          mstore(add(1056, Preco),mload(add(96,Q)  )) 
          mstore(add(1088, Preco),1 )
          mstore(add(1120, Preco),1 )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[2], Q[3],1,1, gx,gy);
         assembly{
          //  Prec[9]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1152, Preco),X )
          mstore(add(1184, Preco),Y ) 
          mstore(add(1216, Preco),ZZ )
          mstore(add(1248, Preco),ZZZ )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[2], Q[3],1, 1, gpow2p128_x,gpow2p128_y);
        assembly{
          //  Prec[10]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1280, Preco),X )
          mstore(add(1312, Preco),Y ) 
          mstore(add(1344, Preco),ZZ )
          mstore(add(1376, Preco),ZZZ )
         }
      
        (X,Y,ZZ,ZZZ)=ec_AddN( X, Y, ZZ, ZZZ, gx, gy);
         assembly{
          //  Prec[11]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1408, Preco),X )
          mstore(add(1440, Preco),Y ) 
          mstore(add(1472, Preco),ZZ )
          mstore(add(1504, Preco),ZZZ )
         }
        
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[0],Q[1],1,1, Q[2], Q[3]);
         assembly{
          //  Prec[12]
          mstore(add(1536, Preco),X )
          mstore(add(1568, Preco),Y ) 
          mstore(add(1600, Preco),ZZ )
          mstore(add(1632, Preco),ZZZ )
         }
        
        (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ, gx, gy);
         assembly{
          //  Prec[13]
          mstore(add(1664, Preco),X )
          mstore(add(1696, Preco),Y ) 
          mstore(add(1728, Preco),ZZ )
          mstore(add(1760, Preco),ZZZ )
         }
        //TODO load
        assembly{
         X:= mload(add(768, Preco) )
         Y:= mload(add(800, Preco) )
         ZZ:= mload(add(832, Preco) )
         ZZZ:=mload(add(864, Preco) )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( X ,Y ,ZZ , ZZZ, Q[2], Q[3]);
         assembly{
          //  Prec[14]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1792, Preco),X )
          mstore(add(1824, Preco),Y ) 
          mstore(add(1856, Preco),ZZ )
          mstore(add(1888, Preco),ZZZ )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ,gx,gy);
         assembly{
          //  Prec[15]
          mstore(add(1920, Preco),X )
          mstore(add(1952, Preco),Y ) 
          mstore(add(1984, Preco),ZZ )
          mstore(add(2016, Preco),ZZZ )
        
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
    

