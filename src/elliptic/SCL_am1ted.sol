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
/* This file implements elliptic curve over reduced twisted edwards form, with extended coordinates */
/* (dm1=>d=-1, ted= twisted edwards) */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { p, d, a, gx, gy, n, pMINUS_2, nMINUS_2, deux_d, scaling_factor, unscaling_factor } from "@solidity/include/SCL_field.h.sol"; 
import { pModInv } from "@solidity/modular/SCL_modular.sol"; 

    //https://hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html;"add-2008-hwcd-3"
    function ec_Add(uint256 x1, uint256 y1, uint256 z1, uint256 t1, uint256 x2, uint256 y2, uint256 z2, uint256 t2)
        pure
        returns (uint256 x3, uint256 y3, uint256 z3, uint256 t3)
    {
        unchecked {
            assembly {
                x3 := addmod(y1, sub(p, x1), p) //   = (Y1-X1)
                t3 := addmod(y2, sub(p, x2), p) //     (Y2-X2)

                y3 := mulmod(x3, t3, p) // A = (Y1-X1)*(Y2-X2)
                x3 := mulmod(addmod(x1, y1, p), addmod(x2, y2, p), p) // B = (Y1+X1)*(Y2+X2)

                let P3 := mulmod(mulmod(t1, t2, p), deux_d, p) //  C = T1*2*d*T2
                t3 := mulmod(z1, z2, p)
                let P4 := mulmod(t3, 2, p) //   D = Z1*2*Z2
                let P5 := addmod(x3, sub(p, y3), p) //E = B-A
                let P6 := addmod(x3, y3, p) //H=B+A
                t3 := mulmod(P5, P6, p) //T3 = E*H,  not required for Dbl input
                z3 := addmod(P4, sub(p, P3), p) //F = D-C
                x3 := mulmod(P5, z3, p) // X3 = E*F
                P5 := addmod(P4, P3, p) //G = D+C
                y3 := mulmod(P5, P6, p) //Y3 = G*H
                z3 := mulmod(z3, P5, p) //  Z3 = F*G
            }
        }
        return (x3, y3, z3, t3);
    }

    //scaling from unreduced form to reduced form
    function ec_Scaling(uint256 xin, uint256 yin) pure returns(uint256 x, uint256 y)
    {
        return (mulmod(xin,scaling_factor,p), yin);
    }

    //unscaling to unreduced form
    function ec_Unscaling(uint256 xin, uint256 yin) pure returns(uint256 x, uint256 y)
    {
          return (mulmod(xin,unscaling_factor,p), yin);

    }



     function ec_Normalize(uint256 x, uint256 y, uint256 z, uint256 t) view returns (uint256 x1, uint256 y1)  {
        if(mulmod(mulmod(x,y,p),z,p)!=t ){
            revert();
        }
        uint256 zInv = pModInv(z); //1/zzz
        y1 = mulmod(y, zInv, p); //Y/zzz
        x1 = mulmod(x, zInv, p); //Y/zzz
      

     }


   function ecAff_isOnCurve(uint256 x, uint256 y) pure returns (bool b) {

        uint256 x2 = mulmod(x, x, p);
        uint256 y2 = mulmod(y, y, p);
        uint256 dy2 = mulmod(d, y2, p); //dy2
        uint256 dy2x2 = mulmod(x2, dy2, p); //dx2y2

        dy2x2 = addmod(x2, addmod(1, dy2x2, p), p); //x2+dx2y2+1 == y2 ?

        return (addmod(p - y2, dy2x2, p) == 0);
    }