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
  function ec_AddN_u4(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 xN, uint256 yN) 
  pure 
  returns (uint256[4] memory res){
    
    (res[0], res[1], res[2], res[3])=ec_AddN( x1, y1, zz1, zzz1, xN, yN);

    return res;
  }

  function ec_MultiplierPrec(uint256 [4] memory Q) pure returns(uint256[4][16] memory Prec) 
  {
        Prec[0]=[_ZERO_U256,_ZERO_U256,_ZERO_U256,_ZERO_U256];
        Prec[1]=[gx,gy,1,1];
        Prec[2]=[gpow2p128_x,gpow2p128_y,1,1];
        Prec[3]=ec_AddN_u4( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
        
        Prec[4]=[Q[0],Q[1],1,1];
        Prec[5]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
        Prec[6]=ec_AddN_u4(gpow2p128_x,gpow2p128_y,1,1, Q[0], Q[1]);
        Prec[7]=ec_AddN_u4(Prec[6][0],Prec[6][1], Prec[6][2], Prec[6][3], gx, gy);
        
        Prec[8]=[Q[2],Q[3],1,1];
        Prec[9]=ec_AddN_u4( Q[2], Q[3],1,1, gx,gy);
        Prec[10]=ec_AddN_u4( Q[2], Q[3],1, 1, gpow2p128_x,gpow2p128_y);
        Prec[11]=ec_AddN_u4( Prec[3][0],Prec[3][1], Prec[3][2], Prec[3][3],Q[2], Q[3]);
        Prec[12]=ec_AddN_u4( Q[0],Q[1],1,1, Q[2], Q[3]);
        Prec[13]=ec_AddN_u4( Prec[5][0],Prec[5][1], Prec[5][2], Prec[5][3], Q[2], Q[3]);
        Prec[14]=ec_AddN_u4( Prec[6][0],Prec[6][1], Prec[6][2], Prec[6][3], Q[2], Q[3]);
        Prec[15]=ec_AddN_u4( Prec[7][0],Prec[7][1], Prec[7][2], Prec[7][3], Q[2], Q[3]);

  }


  function ec_mulmuladdX_noasm(
       /* uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 Q2, 
        uint256 Q3, //affine rep for precomputations*/
        uint256 [4] memory Q,
        uint256 scalar_u,
        uint256 scalar_v
    ) view returns (uint256 X) {
        uint256 mask=1<<127;
        /* I. precomputation phase */
        uint256[4][16] memory Prec; 
        if(scalar_u==0&&scalar_v==0){
            return 0;
        }
        uint256 Y;
        uint256 ZZZ;
        uint256 ZZ;
        
        {
       
        Prec[1]=[gx,gy,1,1];
        Prec[2]=[gpow2p128_x,gpow2p128_y,1,1];
        Prec[3]=ec_AddN_u4( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
        
        Prec[4]=[Q[0],Q[1],1,1];
        Prec[5]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
        Prec[6]=ec_AddN_u4(gpow2p128_x,gpow2p128_y,1,1, Q[0], Q[1]);
        Prec[7]=ec_AddN_u4(Prec[6][0],Prec[6][1], Prec[6][2], Prec[6][3], gx, gy);
        
        Prec[8]=[Q[2],Q[3],1,1];
        Prec[9]=ec_AddN_u4( Q[2], Q[3],1,1, gx,gy);
        Prec[10]=ec_AddN_u4( Q[2], Q[3],1, 1, gpow2p128_x,gpow2p128_y);
        Prec[11]=ec_AddN_u4( Prec[3][0],Prec[3][1], Prec[3][2], Prec[3][3],Q[2], Q[3]);
        Prec[12]=ec_AddN_u4( Q[0],Q[1],1,1, Q[2], Q[3]);
        Prec[13]=ec_AddN_u4( Prec[5][0],Prec[5][1], Prec[5][2], Prec[5][3], Q[2], Q[3]);
        Prec[14]=ec_AddN_u4( Prec[6][0],Prec[6][1], Prec[6][2], Prec[6][3], Q[2], Q[3]);
        Prec[15]=ec_AddN_u4( Prec[7][0],Prec[7][1], Prec[7][2], Prec[7][3], Q[2], Q[3]);
        }

        uint256 quadribit;
        uint256 hi_u=scalar_u>>128;
        uint256 hi_v=scalar_v>>128;
        
        /*II. First MSB bit*/
        do{
              //            quadribit=scalar_u&mask+2*((hi_u&mask)!=0)+4*((scalar_v&mask)!=0)+8*((hi_v&mask)!=0);
               assembly{
                quadribit:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(hi_u, mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(hi_v, mask))))))

            }
            mask>>=1;
        }
        while(quadribit==0);

        X=Prec[quadribit][0];
        Y=Prec[quadribit][1];
        ZZ=Prec[quadribit][2];
        ZZZ=Prec[quadribit][3];
        
        /*III. Main loop */
        while(mask!=0)
        {
            (X,Y,ZZ,ZZZ)=ec_Dbl(X,Y,ZZ,ZZZ);
            //TODO, replace mul by shifts
            assembly{
                 quadribit:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(hi_u, mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(hi_v, mask))))))

            }
           mask>>=1;
            if(quadribit!=0){
              (X,Y,ZZ,ZZZ)=ec_Add(X,Y,ZZ,ZZZ, Prec[quadribit][0], Prec[quadribit][1],Prec[quadribit][2],Prec[quadribit][3]);
            }
        }
       

        (X,)=ec_Normalize(X,Y,ZZ,ZZZ);
    }

  //one step before full inline assembly
  function ec_mulmuladdX_hybrid(
       /* uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 Q2, 
        uint256 Q3, //affine rep for precomputations*/
        uint256 [4] memory Q,
        uint256 scalar_u,
        uint256 scalar_v
    ) view returns (uint256 X) {
        uint256 mask=1<<127;
        /* I. precomputation phase */
        uint256[4][16] memory Prec; 
        if(scalar_u==0&&scalar_v==0){
            return 0;
        }
        uint256 Y;
        uint256 ZZZ;
        uint256 ZZ;
               
        Prec[1]=[gx,gy,1,1];
        Prec[2]=[gpow2p128_x,gpow2p128_y,1,1];
        Prec[3]=ec_AddN_u4( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
        
        Prec[4]=[Q[0],Q[1],1,1];
        Prec[5]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
        Prec[6]=ec_AddN_u4(gpow2p128_x,gpow2p128_y,1,1, Q[0], Q[1]);
        Prec[7]=ec_AddN_u4(Prec[6][0],Prec[6][1], Prec[6][2], Prec[6][3], gx, gy);
        
        Prec[8]=[Q[2],Q[3],1,1];
        Prec[9]=ec_AddN_u4( Q[2], Q[3],1,1, gx,gy);
        Prec[10]=ec_AddN_u4( Q[2], Q[3],1, 1, gpow2p128_x,gpow2p128_y);
        Prec[11]=ec_AddN_u4( Prec[3][0],Prec[3][1], Prec[3][2], Prec[3][3],Q[2], Q[3]);
        Prec[12]=ec_AddN_u4( Q[0],Q[1],1,1, Q[2], Q[3]);
        Prec[13]=ec_AddN_u4( Prec[5][0],Prec[5][1], Prec[5][2], Prec[5][3], Q[2], Q[3]);
        Prec[14]=ec_AddN_u4( Prec[6][0],Prec[6][1], Prec[6][2], Prec[6][3], Q[2], Q[3]);
        Prec[15]=ec_AddN_u4( Prec[7][0],Prec[7][1], Prec[7][2], Prec[7][3], Q[2], Q[3]);
        
        uint256 quadribit=0;
       // uint256 hi_u=scalar_u>>128;
       // uint256 hi_v=scalar_v>>128;
        
        /*II. First MSB bit*/
              //            quadribit=scalar_u&mask+2*((hi_u&mask)!=0)+4*((scalar_v&mask)!=0)+8*((hi_v&mask)!=0);
               assembly{
                for {} iszero(quadribit) { mask := shr(1, mask) }{
                quadribit:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(shr(128, scalar_u), mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(shr(128, scalar_v), mask))))))

                }
                
           }


        X=Prec[quadribit][0];
        Y=Prec[quadribit][1];
        ZZ=Prec[quadribit][2];
        ZZZ=Prec[quadribit][3];
        
        /*III. Main loop */
        while(mask!=0)
        {
            //(X,Y,ZZ,ZZZ)=ec_Dbl(X,Y,ZZ,ZZZ);
            //TODO, replace mul by shifts
            assembly{
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
                Y:=sub(p,Y)
                quadribit:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(shr(128, scalar_u), mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(shr(128, scalar_v), mask))))))

                mask:=shr(1,mask)
            }
            uint256 temp;
            
            assembly{
              temp:=mload(add(Prec,shl(7,quadribit)))//X
            }
           // console.log("read", Prec[quadribit][0]);


            if(quadribit!=0){
              (X,Y,ZZ,ZZZ)=ec_Add(X,Y,ZZ,ZZZ, Prec[quadribit][0], Prec[quadribit][1],Prec[quadribit][2],Prec[quadribit][3]);
            }
        }
        (X,)=ec_Normalize(X,Y,ZZ,ZZZ);
    }


 