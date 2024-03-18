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


import { p, gx, gy, n, pMINUS_2, nMINUS_2 } from "@solidity/include/SCL_field.h.sol"; 
import { ModInv, nModInv } from "@solidity/modular/SCL_modular.sol"; 
import {ec_mulmuladdX, ec_mulmuladd_S8_extcode, ecGenMulmuladdW} from  "@solidity/include/SCL_ecmulmuladd.h.sol"; 
import "@solidity/elliptic/SCL_mulmuladdX_fullgen_b4.sol";


  /* classic shamir's trick*/
  function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) view returns (bool) {
        // check the validity of the signature
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }

        // check the public key is on the curve is done by the caller
        /* if (!ECDSA.affIsOnCurve(qx, qy)) {
            return false;
        }*/

        // calculate the scalars used for the multiplication of the point
        uint256 sInv = nModInv(s);
        uint256 scalar_u = mulmod(uint256(message), sInv, n);
        uint256 scalar_v = mulmod(r, sInv, n);

        uint256 x1 = ec_mulmuladdX(qx, qy, scalar_u, scalar_v);

        assembly {
            x1 := addmod(x1, sub(n, r), n)
        }

        return x1 == 0;
    }
 
  
    function ecdsa_sign(bytes32 message, uint256 k , uint256 kpriv) view returns(uint256 r, uint256 s)
    {
        r=  ec_mulmuladdX(0,0, k, 0) ;//Calculate the curve point k.G (abuse ecmulmul add with v=0)
        r=addmod(0,r, n); 
        s=mulmod( nModInv(k), addmod(uint256(message), mulmod(r, kpriv, n), n), n);//s=k^-1.(h+r.kpriv)

        if(r==0||s==0){
            revert();
        }
    }


  /*  precomputations version*/
  function ecdsa_verify(bytes32 message, uint256 r, uint256 s, address precomputations) view returns (bool) {
        // check the validity of the signature
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }

        // check the public key is on the curve is done by the caller
        /* if (!ECDSA.affIsOnCurve(qx, qy)) {
            return false;
        }*/

        // calculate the scalars used for the multiplication of the point
        uint256 sInv = nModInv(s);
        uint256 scalar_u = mulmod(uint256(message), sInv, n);
        uint256 scalar_v = mulmod(r, sInv, n);

        uint256 x1 = ec_mulmuladd_S8_extcode(scalar_u, scalar_v, precomputations);

        assembly {
            x1 := addmod(x1, sub(n, r), n)
        }

        return x1 == 0;
    }

/* One single point precomputation version*/ 
function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy, uint256 q2p128_x, uint256 q2p128_y)
view returns (bool)
{
    // check the validity of the signature
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }

      // calculate the scalars used for the multiplication of the point
        uint256 sInv = nModInv(s);
        uint256 scalar_u = mulmod(uint256(message), sInv, n);
        uint256 scalar_v = mulmod(r, sInv, n);

        uint256 x1 = ec_mulmuladdX([qx, qy, q2p128_x, q2p128_y], scalar_u, scalar_v);


        assembly {
            x1 := addmod(x1, sub(n, r), n)
        }

        return x1 == 0;

}


/* shamir's trick+windowed, meant to replace classic shamir*/ 
function ecdsa_verifyW(bytes32 message, uint256 r, uint256 s, uint256 qx, uint256 qy) view returns (bool) {
        // check the validity of the signature
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }

        // check the public key is on the curve is done by the caller
        /* if (!ECDSA.affIsOnCurve(qx, qy)) {
            return false;
        }*/

        // calculate the scalars used for the multiplication of the point
        uint256 sInv = nModInv(s);
        uint256 scalar_u = mulmod(uint256(message), sInv, n);
        uint256 scalar_v = mulmod(r, sInv, n);

        uint256 x1 = ecGenMulmuladdW(qx, qy, scalar_u, scalar_v);

        assembly {
            x1 := addmod(x1, sub(n, r), n)
        }

        return x1 == 0;
    }
 
function ecdsa_verifyG(bytes32 message, uint256 r, uint256 s, uint256[10] memory Qpa, uint256 order) 
view returns (bool)
{
    // check the validity of the signature
        if (r == 0 || r >= order || s == 0 || s >= order) {
            return false;
        }

      // calculate the scalars used for the multiplication of the point
        uint256 sInv = ModInv(s,order ); //note that s cannot be 0 as required
        uint256 scalar_u = mulmod(uint256(message), sInv, order);
        uint256 scalar_v = mulmod(r, sInv, order);
       // uint256[10] memory Qpa=[qx, qy,q2p128_x, q2p128_y ,p, a, gx, gy, gpow2p128_x, gpow2p128_y];

        uint256 x1 = ecGenMulmuladdX_store(Qpa, scalar_u, scalar_v);


        assembly {
            x1 := addmod(x1, sub(order, r), order)
        }

         return x1 == 0;
}




