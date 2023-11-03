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

import {_HIBIT_CURVE} from "@solidity/include/SCL_field.h.sol";
import {ec_Add, ec_AddN, ec_Dbl, ec_Normalize} from "@solidity/include/SCL_elliptic.h.sol";


/*STATUS: UNTESTED*/
function ec_scalarmulN(uint256 scalar, uint Gx, uint Gy)
        view
        returns (
            
            uint256 x,
            uint256 y
        )
    {
        uint256 zz;
        uint256 zzz;

        if (scalar == 0) {
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

