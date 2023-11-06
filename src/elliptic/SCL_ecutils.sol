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
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import { p, a,b ,gx, gy, n, pMINUS_2, nMINUS_2, MINUS_1 } from "@solidity/include/SCL_field.h.sol";
import {_HIBIT_CURVE} from "@solidity/include/SCL_field.h.sol";
import {ec_Add, ec_Aff_Add, ec_AddN, ec_Dbl, ec_Normalize, ecAff_IsZero} from "@solidity/include/SCL_elliptic.h.sol";



/**
  * @dev Add two elliptic curve points in affine coordinates. Deal with P=Q
  */

function ec_Aff_Add(uint256 x0, uint256 y0, uint256 x1, uint256 y1)  view returns (uint256, uint256)  {
        uint256 zz0;
        uint256 zzz0;

        if (ecAff_IsZero(x0, y0)) return (x1, y1);
        if (ecAff_IsZero(x1, y1)) return (x0, y0);
        if((x0==x1)&&(y0==y1)) {
            (x0, y0, zz0, zzz0) = ec_Dbl(x0, y0,1,1);
        }
        else{
            (x0, y0, zz0, zzz0) = ec_AddN(x0, y0, 1, 1, x1, y1);
        }

        return ec_Normalize(x0, y0, zz0, zzz0);
    }

    /**
      * @dev Coron projective shuffling, take as input alpha as blinding factor
    */
   function ec_Coronize(uint256 alpha, uint256 x, uint256 y,  uint256 zz, uint256 zzz) pure  returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3)
   {
       
        uint256 alpha2=mulmod(alpha,alpha,p);
       
        x3=mulmod(alpha2, x,p); //alpha^-2.x
        y3=mulmod(mulmod(alpha, alpha2,p), y,p);

        zz3=mulmod(zz,alpha2,p);//alpha^2 zz
        zzz3=mulmod(zzz,mulmod(alpha, alpha2,p),p);//alpha^3 zzz
        
        return (x3, y3, zz3, zzz3);
   }


    //precomputations for 8 dimensional trick
    function ec_SetPrec8( uint256 Qx, uint256 Qy)  view returns( bytes memory precomputations)
    {
     uint[2][256] memory Prec;
     uint[2][8] memory Pow64_PQ; //store P, 64P, 128P, 192P, Q, 64Q, 128Q, 192Q
     
     //the trivial private keys 1 and -1 are forbidden
     if(Qx==gx)
     {
        revert("trivial private key not allowed");
     }
     Pow64_PQ[0][0]=gx;
     Pow64_PQ[0][1]=gy;
    
     Pow64_PQ[4][0]=Qx;
     Pow64_PQ[4][1]=Qy;
     
     /* raise to multiplication by 64 by 64 consecutive doublings*/
     for(uint j=1;j<4;j++){
        uint256 x;
        uint256 y;
        uint256 zz;
        uint256 zzz;
        
      	(x,y,zz,zzz)=ec_Dbl(Pow64_PQ[j-1][0],   Pow64_PQ[j-1][1], 1, 1);
      	(Pow64_PQ[j][0],   Pow64_PQ[j][1])=ec_Normalize(x,y,zz,zzz);
        (x,y,zz,zzz)=ec_Dbl(Pow64_PQ[j+3][0],   Pow64_PQ[j+3][1], 1, 1);
     	(Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1])=ec_Normalize(x,y,zz,zzz);

     	for(uint i=0;i<63;i++){
     	(x,y,zz,zzz)=ec_Dbl(Pow64_PQ[j][0],   Pow64_PQ[j][1],1,1);
        (Pow64_PQ[j][0],   Pow64_PQ[j][1])=ec_Normalize(x,y,zz,zzz);
     	(x,y,zz,zzz)=ec_Dbl(Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1],1,1);
        (Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1])=ec_Normalize(x,y,zz,zzz);
     	}
     }
     
     /* neutral point */
     Prec[0][0]=0;
     Prec[0][1]=0;
     
     	
     for(uint i=1;i<256;i++)
     {       
        Prec[i][0]=0;
        Prec[i][1]=0;
        
        for(uint j=0;j<8;j++)
        {
        	if( (i&(1<<j))!=0){
        		(Prec[i][0], Prec[i][1])=ec_Aff_Add(Pow64_PQ[j][0], Pow64_PQ[j][1], Prec[i][0], Prec[i][1]);
        	}
        }
         
     }
     return abi.encodePacked(Prec);
    }

    function ec_scalarPow2mul(uint256 PowerOfTwo, uint256 X,uint256 Y, uint256 ZZ, uint256 ZZZ) view returns (uint256 x, uint256 y){
        
        for(uint256 i=0;i<PowerOfTwo;i++)
        {
            (X, Y, ZZ, ZZZ)=ec_Dbl(X, Y, ZZ, ZZZ);
        }
        (x,y)=ec_Normalize(X,Y,ZZ,ZZZ);
    }
    
function ec_scalarmulN(uint256 scalar, uint Gx, uint Gy)
        view
        returns (
            
            uint256 x,
            uint256 y
        )
        {
        uint256 zz;
        uint256 zzz;

        if(scalar == 0) {
            return (0,  0);
        } 
       
        uint256 mask=1<<_HIBIT_CURVE;

        while(mask&scalar==0)
        {
            mask=mask>>1;
        }

        x = Gx;
        y = Gy;
        zz = 1;
        zzz= 1;
        mask=mask>>1;

        while (mask > 0) {
            (x,y,zz,zzz) = ec_Dbl(x,y,zz,zzz);

            //todo: homogeneous addN required here
            if ( (scalar & mask) != 0x00) {
                (x,y,zz,zzz) = ec_AddN(x,y,zz,zzz, Gx, Gy);
            }

             mask=mask>>1;
        }

        return ec_Normalize(x,y,zz,zzz);    
    }

 //UNTESTED
 // a slow ecMulmuladd for testing purposes
function ec_Mulmuladd_schoolbook(
            uint256 scalar_u,
            uint256 Gx,
            uint256 Gy,
            uint256 scalar_v,
             uint256 Qx,
            uint256 Qy)
        view
        returns (
            uint256 x,
            uint256 y
        )
        {
        uint256 xp;
        uint256 yp;

        (x,y) = ec_scalarmulN(scalar_u, Gx, Gy );
        (xp,yp)=ec_scalarmulN(scalar_v, Qx, Qy);
        (x,y,xp,yp) = ec_AddN(x,y, 1, 1, xp,yp);
         return ec_Normalize(x,y,xp,yp);    
    }


 /**
     * @dev Check if a point in affine coordinates is on the curve (reject Neutral that is indeed on the curve).
     */
    function ecAff_isOnCurve(uint256 x, uint256 y)  pure returns (bool) {
        if ( ((0 == x)&&( 0 == y)) || x == p ||   y == p) {
            return false;
        }
        unchecked {
            uint256 LHS = mulmod(y, y, p); // y^2
            uint256 RHS = addmod(mulmod(mulmod(x, x, p), x, p), mulmod(x, a, p), p); // x^3+ax
            RHS = addmod(RHS, b, p); // x^3 + a*x + b

            return LHS == RHS;
        }
    }

