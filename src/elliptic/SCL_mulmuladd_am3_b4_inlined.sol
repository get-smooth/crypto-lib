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

  /* just for convenience*/
  function ec_AddN_u4b(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 xN, uint256 yN) 
  pure 
  returns (uint256[4] memory res){
    
    (res[0], res[1], res[2], res[3])=ec_AddN( x1, y1, zz1, zzz1, xN, yN);

    return res;
  }

  //WIP: for bench only, TODO: pass the tests
  function ec_mulmuladdX_b4(
       /* uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 Q2, 
        uint256 Q3, //affine rep for precomputations*/
        uint256 [4] memory Q,
        uint256 scalar_u,
        uint256 scalar_v
    ) view returns (uint256 X) {
       
        /* I. precomputation phase */
        uint256[4][16] memory Prec; //slot 0: use as temp to reduce stack|| 1-15: stores precomputations
        if(scalar_u==0&&scalar_v==0){
            return 0;
        }
        uint256 Y;
        uint256 zzz;
        uint256 zz=1<<127;
       
         unchecked{  
        {
        Prec[1]=[gx,gy,1,1];
        Prec[2]=[gpow2p128_x,gpow2p128_y,1,1];
        Prec[3]=ec_AddN_u4b( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
        
        Prec[4]=[Q[0],Q[1],1,1];
        Prec[5]=ec_AddN_u4b(Q[0],Q[1],1,1, gx,gy);
        Prec[6]=ec_AddN_u4b(gpow2p128_x,gpow2p128_y,1,1, Q[0], Q[1]);
        Prec[7]=ec_AddN_u4b(Prec[6][0],Prec[6][1], Prec[6][2], Prec[6][3], gx, gy);
        
        Prec[8]=[Q[2],Q[3],1,1];
        Prec[9]=ec_AddN_u4b( Q[2], Q[3],1,1, gx,gy);
        Prec[10]=ec_AddN_u4b( Q[2], Q[3],1, 1, gpow2p128_x,gpow2p128_y);
        Prec[11]=ec_AddN_u4b( Prec[3][0],Prec[3][1], Prec[3][2], Prec[3][3],Q[2], Q[3]);
        Prec[12]=ec_AddN_u4b( Q[0],Q[1],1,1, Q[2], Q[3]);
        Prec[13]=ec_AddN_u4b( Prec[5][0],Prec[5][1], Prec[5][2], Prec[5][3], Q[2], Q[3]);
        Prec[14]=ec_AddN_u4b( Prec[6][0],Prec[6][1], Prec[6][2], Prec[6][3], Q[2], Q[3]);
        Prec[15]=ec_AddN_u4b( Prec[7][0],Prec[7][1], Prec[7][2], Prec[7][3], Q[2], Q[3]);
        }
        }

       
        //uint256 hi_u=scalar_u>>128;
        //uint256 hi_v=scalar_v>>128;
        
        /*II. First MSB bit*/
        do{
            
               assembly{
                zzz:=add(add(sub(1,iszero(and(scalar_u, zz))), mul(2,sub(1,iszero(and(shr(128, scalar_u), zz))))),
                           add(mul(4,sub(1,iszero(and(scalar_v, zz)))), mul(8,sub(1,iszero(and(shr(128, scalar_v), zz))))))

            }
            zz>>=1;
        }
        while(zzz==0);

        X=Prec[zzz][0];
        Y=Prec[zzz][1];
        zz=Prec[zzz][2];
        zzz=Prec[zzz][3];
        
        /*III. Main loop */
        unchecked{
        assembly{
          let mask:=zz
          
          for {} gt(mask, 0) { mask := shr(1, mask) } {
               
               //inlined Dbl
               {

                let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, p) // V=U^2
                let T3 := mulmod(X, T2, p) // S = X1*V
                T1 := mulmod(T1, T2, p) // W=UV
                let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
               }
               {
                 let T1:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(shr(128, scalar_u), mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(shr(128, scalar_v), mask))))))
                 mask:=shr(1, mask)
                 if iszero(T1) {
                            Y := sub(p, Y)
                            continue
                        }
                 T1:=shl(7, T1)//precomputed value address offset      
               
                 let T4:=mload(add(Prec,T1))//X2
                 let zzz2:= mload(add(Prec,add(96,T1)))//ZZZ2
                 
                
                 let y2 := addmod(mulmod( mload(add(Prec,add(64,T1))), zzz, p), mulmod(Y,zzz2, p), p)//R=S2-S1
                 T1:=mload(add(Prec,add(64,T1)))//zz2
                 let T2 := addmod(mulmod(T4, zz, p), sub(p, mulmod(X,T1,p)), p)//P=U2-U1

                        //special case ecAdd(P,P)=EcDbl
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(pMINUS_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                let T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p) //X+ZZ
                                let TT1 := addmod(X, sub(p, zz), p) //X-ZZ
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(TT1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }
                  T4 := mulmod(T2, T2, p) //PP
                  T2 := mulmod(T4, T2, p) //PPP
                  zz := mulmod(mulmod(zz, T4, p), T1 ,p)//zz3=zz1*zz2*PP
                  //zzz3=V*ZZ1
                  zzz := mulmod(mulmod(zzz, T1, p), zzz2,p) // zzz3=zzz1*zzz2*PPP
                  T4 := mulmod(X, T4, p)///Q=U1*PP
                  X := addmod(addmod(mulmod(y2, y2, p), sub(p, T1), p), mulmod(pMINUS_2, T4, p), p)
                  Y := addmod(mulmod(addmod(T4, sub(p, X), p), y2, p), mulmod(Y, T1, p), p)
               }
              
          }//end loop
            mstore(add(Prec, 0x60), zz)

                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(Prec, 0x20)
                mstore(add(Prec, 0x20), 0x20)
                mstore(add(Prec, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(Prec, 0x80), pMINUS_2)
                mstore(add(Prec, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, Prec, 0xc0, Prec, 0x20)) { revert(0, 0) }

                zz := mload(Prec)
                X := mulmod(X, zz, p) //X/zz
        }//end assembly
        }//end unchecked

    }
