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


import { p, gx, gy, n, pMINUS_2, nMINUS_2 } from "@solidity/include/SCL_field.h.sol";

    //8 dimensions Shamir's trick, using precomputations stored in Shamir8,  stored as Bytecode of an external
    //contract at given address dataPointer
    //(thx to Lakhdar https://github.com/Kelvyne for EVM storage explanations and tricks)
    // the external tool to generate tables from public key is in the /sage directory
    function ec_mulmuladd_S8_extcode(uint256 scalar_u, uint256 scalar_v, address dataPointer)
         view
        returns (uint256 X /*, uint Y*/ )
    {
        unchecked {
            uint256 zz; // third and  coordinates of the point

            uint256[6] memory T;
            zz = 256; //start index

            while (T[0] == 0) {
                zz = zz - 1;
                //tbd case of msb octobit is null
                T[0] = 64
                    * (
                        128 * ((scalar_v >> zz) & 1) + 64 * ((scalar_v >> (zz - 64)) & 1)
                            + 32 * ((scalar_v >> (zz - 128)) & 1) + 16 * ((scalar_v >> (zz - 192)) & 1)
                            + 8 * ((scalar_u >> zz) & 1) + 4 * ((scalar_u >> (zz - 64)) & 1)
                            + 2 * ((scalar_u >> (zz - 128)) & 1) + ((scalar_u >> (zz - 192)) & 1)
                    );
            }
            assembly {
                extcodecopy(dataPointer, T, mload(T), 64)
                let index := sub(zz, 1)
                X := mload(T)
                let Y := mload(add(T, 32))
                let zzz := 1
                zz := 1

                //loop over 1/4 of scalars thx to Shamir's trick over 8 points
                for {} gt(index, 191) { index := add(index, 191) } {
                    //inline Double
                    {
                        let TT1 := mulmod(2, Y, p) //U = 2*Y1, y free
                        let T2 := mulmod(TT1, TT1, p) // V=U^2
                        let T3 := mulmod(X, T2, p) // S = X1*V
                        let T1 := mulmod(TT1, T2, p) // W=UV
                        let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                        zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                        zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                        X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                        //T2:=mulmod(T4,addmod(T3, sub(p, X),p),p)//M(S-X3)
                        let T5 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)

                        //Y:= addmod(T2, sub(p, mulmod(T1, Y ,p)),p  )//Y3= M(S-X3)-W*Y1
                        Y := addmod(mulmod(T1, Y, p), T5, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                        /* compute element to access in precomputed table */
                    }
                    {
                        let T4 := add(shl(13, and(shr(index, scalar_v), 1)), shl(9, and(shr(index, scalar_u), 1)))
                        let index2 := sub(index, 64)
                        let T3 :=
                            add(T4, add(shl(12, and(shr(index2, scalar_v), 1)), shl(8, and(shr(index2, scalar_u), 1))))
                        let index3 := sub(index2, 64)
                        let T2 :=
                            add(T3, add(shl(11, and(shr(index3, scalar_v), 1)), shl(7, and(shr(index3, scalar_u), 1))))
                        index := sub(index3, 64)
                        let T1 :=
                            add(T2, add(shl(10, and(shr(index, scalar_v), 1)), shl(6, and(shr(index, scalar_u), 1))))

                        //tbd: check validity of formulae with (0,1) to remove conditional jump
                        if iszero(T1) {
                            Y := sub(p, Y)

                            continue
                        }
                        extcodecopy(dataPointer, T, T1, 64)
                    }

                    {
                        /* Access to precomputed table using extcodecopy hack */

                        // inlined EcZZ_AddN
                        if iszero(zz) {
                            X := mload(T)
                            Y := mload(add(T, 32))
                            zz := 1
                            zzz := 1

                            continue
                        }

                        let y2 := addmod(mulmod(mload(add(T, 32)), zzz, p), Y, p)
                        let T2 := addmod(mulmod(mload(T), zz, p), sub(p, X), p)

                        //special case ecAdd(P,P)=EcDbl
                        if iszero(y2) {
                            if iszero(T2) {
                                let T1 := mulmod(pMINUS_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                let T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p) //X+ZZ
                                let TT1 := addmod(X, sub(p, zz), p) //X-ZZ
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                let T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(TT1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        let T4 := mulmod(T2, T2, p)
                        let T1 := mulmod(T4, T2, p) //
                        zz := mulmod(zz, T4, p)
                        //zzz3=V*ZZ1
                        zzz := mulmod(zzz, T1, p) // W=UV/
                        let zz1 := mulmod(X, T4, p)
                        X := addmod(addmod(mulmod(y2, y2, p), sub(p, T1), p), mulmod(pMINUS_2, zz1, p), p)
                        Y := addmod(mulmod(addmod(zz1, sub(p, X), p), y2, p), mulmod(Y, T1, p), p)
                    }
                } //end loop
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

                zz := mload(T)
                X := mulmod(X, zz, p) //X/zz
            }
        } //end unchecked
    }

   

    // improving the extcodecopy trick : append array at end of contract
    function ecZZ_mulmuladd_S8_hackmem(uint256 scalar_u, uint256 scalar_v, uint256 dataPointer)
         view
        returns (uint256 X /*, uint Y*/ )
    {
        uint256 zz; // third and  coordinates of the point

        uint256[6] memory T;
        zz = 256; //start index

        unchecked {
            while (T[0] == 0) {
                zz = zz - 1;
                //tbd case of msb octobit is null
                T[0] = 64
                    * (
                        128 * ((scalar_v >> zz) & 1) + 64 * ((scalar_v >> (zz - 64)) & 1)
                            + 32 * ((scalar_v >> (zz - 128)) & 1) + 16 * ((scalar_v >> (zz - 192)) & 1)
                            + 8 * ((scalar_u >> zz) & 1) + 4 * ((scalar_u >> (zz - 64)) & 1)
                            + 2 * ((scalar_u >> (zz - 128)) & 1) + ((scalar_u >> (zz - 192)) & 1)
                    );
            }
            assembly {
                codecopy(T, add(mload(T), dataPointer), 64)
                X := mload(T)
                let Y := mload(add(T, 32))
                let zzz := 1
                zz := 1

                //loop over 1/4 of scalars thx to Shamir's trick over 8 points
                for { let index := 254 } gt(index, 191) { index := add(index, 191) } {
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                    //T2:=mulmod(T4,addmod(T3, sub(p, X),p),p)//M(S-X3)
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)

                    //Y:= addmod(T2, sub(p, mulmod(T1, Y ,p)),p  )//Y3= M(S-X3)-W*Y1
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    /* compute element to access in precomputed table */
                    T4 := add(shl(13, and(shr(index, scalar_v), 1)), shl(9, and(shr(index, scalar_u), 1)))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(12, and(shr(index, scalar_v), 1)), shl(8, and(shr(index, scalar_u), 1))))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(11, and(shr(index, scalar_v), 1)), shl(7, and(shr(index, scalar_u), 1))))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(10, and(shr(index, scalar_v), 1)), shl(6, and(shr(index, scalar_u), 1))))
                    //index:=add(index,192), restore index, interleaved with loop

                    //tbd: check validity of formulae with (0,1) to remove conditional jump
                    if iszero(T4) {
                        Y := sub(p, Y)

                        continue
                    }
                    {
                        /* Access to precomputed table using extcodecopy hack */
                        codecopy(T, add(T4, dataPointer), 64)

                        // inlined EcZZ_AddN

                        let y2 := addmod(mulmod(mload(add(T, 32)), zzz, p), Y, p)
                        T2 := addmod(mulmod(mload(T), zz, p), sub(p, X), p)
                        T4 := mulmod(T2, T2, p)
                        T1 := mulmod(T4, T2, p)
                        T2 := mulmod(zz, T4, p) // W=UV
                        zzz := mulmod(zzz, T1, p) //zz3=V*ZZ1
                        let zz1 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, T1), p), mulmod(pMINUS_2, zz1, p), p)
                        Y := addmod(mulmod(addmod(zz1, sub(p, T4), p), y2, p), mulmod(Y, T1, p), p)
                        zz := T2
                        X := T4
                    }
                } //end loop
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

                zz := mload(T)
                X := mulmod(X, zz, p) //X/zz
            }
        } //end unchecked
    }



