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


  function ec_mulmuladdX(
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
//            quadribit=scalar_u&mask+2*((hi_u&mask)!=0)+4*((scalar_v&mask)!=0)+8*((hi_v&mask)!=0);
            mask>>=1;
            if(quadribit!=0){
              (X,Y,ZZ,ZZZ)=ec_Add(X,Y,ZZ,ZZZ, Prec[quadribit][0], Prec[quadribit][1],Prec[quadribit][2],Prec[quadribit][3]);
            }
        }
       

        (X,)=ec_Normalize(X,Y,ZZ,ZZZ);
    }
