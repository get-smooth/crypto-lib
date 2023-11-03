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
/* (am3->a=-3, sw=short weierstrass) */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;
 

import { p, gx, gy, n, pMINUS_2, nMINUS_2 } from "@solidity/include/SCL_field.h.sol"; 
 
import { pModInv } from "@solidity/modular/SCL_modular.sol"; 

 /* @dev Sutherland2008 doubling
 /* The "dbl-2008-s-1" doubling formulas */
function ec_Dbl(uint256 x, uint256 y, uint256 zz, uint256 zzz)
       pure
        returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3)
    {
        unchecked {
            assembly {
                P0 := mulmod(2, y, p) //U = 2*Y1
                P2 := mulmod(P0, P0, p) // V=U^2
                P3 := mulmod(x, P2, p) // S = X1*V
                P1 := mulmod(P0, P2, p) // W=UV
                P2 := mulmod(P2, zz, p) //zz3=V*ZZ1
                zz := mulmod(3, mulmod(addmod(x, sub(p, zz), p), addmod(x, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                P0 := addmod(mulmod(zz, zz, p), mulmod(pMINUS_2, P3, p), p) //X3=M^2-2S
                x := mulmod(zz, addmod(P3, sub(p, P0), p), p) //M(S-X3)
                P3 := mulmod(P1, zzz, p) //zzz3=W*zzz1
                P1 := addmod(x, sub(p, mulmod(P1, y, p)), p) //Y3= M(S-X3)-W*Y1
            }
        }
        return (P0, P1, P2, P3);
    }

/**
  * @dev Sutherland2008 add a ZZ point with a normalized point and greedy formulae
  * warning: assume that P1(x1,y1)!=P2(x2,y2), true in multiplication loop with prime order (cofactor 1)
   */
    function ec_AddN(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2)
    pure
        returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3)
    {
        unchecked {
            if (y1 == 0) {
                return (x2, y2, 1, 1);
            }

            assembly {
                y1 := sub(p, y1)
                y2 := addmod(mulmod(y2, zzz1, p), y1, p)
                x2 := addmod(mulmod(x2, zz1, p), sub(p, x1), p)
                P0 := mulmod(x2, x2, p) //PP = P^2
                P1 := mulmod(P0, x2, p) //PPP = P*PP
                P2 := mulmod(zz1, P0, p) ////ZZ3 = ZZ1*PP
                P3 := mulmod(zzz1, P1, p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, P0, p) //Q = X1*PP
                P0 := addmod(addmod(mulmod(y2, y2, p), sub(p, P1), p), mulmod(pMINUS_2, zz1, p), p) //R^2-PPP-2*Q
                P1 := addmod(mulmod(addmod(zz1, sub(p, P0), p), y2, p), mulmod(y1, P1, p), p) //R*(Q-X3)
            }
            //end assembly
        } //end unchecked
        return (P0, P1, P2, P3);
    }

function ec_Add(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2, uint256 zz2, uint256 zzz2)  pure returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3)
  {
    uint256 u1=mulmod(x1,zz2,p); // U1 = X1*ZZ2
    uint256 u2=mulmod(x2, zz1,p);               //  U2 = X2*ZZ1
    u2=addmod(u2, p-u1, p);//  P = U2-U1
    x1=mulmod(u2, u2, p);//PP
    x2=mulmod(x1, u2, p);//PPP
    
    zz3=mulmod(x1, mulmod(zz1, zz2, p),p);//ZZ3 = ZZ1*ZZ2*PP  
    zzz3=mulmod(zzz1, mulmod(zzz2, x2, p),p);//ZZZ3 = ZZZ1*ZZZ2*PPP

    zz1=mulmod(y1, zzz2,p);  // S1 = Y1*ZZZ2
    zz2=mulmod(y2, zzz1, p);    // S2 = Y2*ZZZ1 
    zz2=addmod(zz2, p-zz1, p);//R = S2-S1
    zzz1=mulmod(u1, x1,p); //Q = U1*PP
    x3= addmod(addmod(mulmod(zz2, zz2, p), p-x2,p), mulmod(pMINUS_2, zzz1,p),p); //X3 = R2-PPP-2*Q
    y3=addmod( mulmod(zz2, addmod(zzz1, p-x3, p),p), p-mulmod(zz1, x2, p),p);//R*(Q-X3)-S1*PPP

    return (x3, y3, zz3, zzz3);
  }

  /* homogeneous addition (handles the double case)*/
  function ec_hAdd(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2, uint256 zz2, uint256 zzz2)  pure returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3)
  {


  }



/**
     * /* @dev Convert from XYZZ rep to affine rep
     */
    /*    https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html#addition-add-2008-s*/
    function ec_Normalize(uint256 x, uint256 y, uint256 zz, uint256 zzz) view returns (uint256 x1, uint256 y1)  {
        uint256 zzzInv = pModInv(zzz); //1/zzz
        y1 = mulmod(y, zzzInv, p); //Y/zzz
        uint256 _b = mulmod(zz, zzzInv, p); //1/z
        zzzInv = mulmod(_b, _b, p); //1/zz
        x1 = mulmod(x, zzzInv, p); //X/zz
    }
    
    
  function ecAff_IsZero(uint256 x, uint256 y) pure returns (bool flag) {
        return ((x==0)&&(y == 0));
    }
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
     
     /* raise to multiplication by 64 by 6 consecutive doubling*/
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