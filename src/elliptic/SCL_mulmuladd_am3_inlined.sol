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
/* It is a simple Shamir's trick from old legacy FCL with inlined code*/
/* (am3->a=-3, sw=short weierstrass) */
pragma solidity >=0.8.19 <0.9.0;

import{gx, gy, p, pMINUS_2, MINUS_1, n} from "@solidity/include/SCL_field.h.sol"; 
import { ec_Aff_Add } from "@solidity/include/SCL_elliptic.h.sol";

    /**
     * @dev Computation of uG+vQ using Strauss-Shamir's trick, G basepoint, Q public key
     *       Returns only x for ECDSA use            
     *      */
   function ec_mulmuladdX(
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v
    ) view returns (uint256 X) {
        uint256 zz;
        uint256 zzz;
        uint256 Y;
        uint256 index = 255;
        uint256 H0;
        uint256 H1;


        unchecked {
            if (scalar_u == 0 && scalar_v == 0) return 0;

            (H0, H1) = ec_Aff_Add(gx, gy, Q0, Q1); 

            assembly {

                

                for { let T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1)) } eq(T4, 0) {
                    index := sub(index, 1)
                    T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))
                } {}
                zz := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                if eq(zz, 1) {
                    X := gx
                    Y := gy
                }
                if eq(zz, 2) {
                    X := Q0
                    Y := Q1
                }
                if eq(zz, 3) {
                    X := H0
                    Y := H1
                }

                index := sub(index, 1)
                zz := 1
                zzz := 1

                for {} gt(MINUS_1, index) { index := sub(index, 1) } {
                    // inlined EcZZ_Dbl
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

                    {
                        //value of dibit
                        T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                        if iszero(T4) {
                            Y := sub(p, Y) //restore the -Y inversion
                            continue
                        } // if T4!=0

                        if eq(T4, 1) {
                            T1 := gx
                            T2 := gy
                        }
                        if eq(T4, 2) {
                            T1 := Q0
                            T2 := Q1
                        }
                        if eq(T4, 3) {
                            T1 := H0
                            T2 := H1
                        }
                        if iszero(zz) {
                            X := T1
                            Y := T2
                            zz := 1
                            zzz := 1
                            continue
                        }
                        // inlined EcZZ_AddN

                        //T3:=sub(p, Y)
                        //T3:=Y
                        let y2 := addmod(mulmod(T2, zzz, p), Y, p) //R
                        T2 := addmod(mulmod(T1, zz, p), sub(p, X), p) //P

                        //special extremely rare case accumulator where EcAdd is replaced by EcDbl, no need to optimize this
                        //todo : construct edge vector case
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(pMINUS_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p)  //X+ZZ
                                let TT1 := addmod(X, sub(p, zz), p) //X-ZZ
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        T4 := mulmod(T2, T2, p) //PP
                        let TT1 := mulmod(T4, T2, p) //PPP, this one could be spared, but adding this register spare gas
                        zz := mulmod(zz, T4, p)
                        zzz := mulmod(zzz, TT1, p) //zz3=V*ZZ1
                        let TT2 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, TT1), p), mulmod(pMINUS_2, TT2, p), p)
                        Y := addmod(mulmod(addmod(TT2, sub(p, T4), p), y2, p), mulmod(Y, TT1, p), p)

                        X := T4
                    }
                } //end loop
                let T := mload(0x40)
                mstore(add(T, 0x60), zz)
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
            } //end assembly
        } //end unchecked

        return X;
    }
 
