/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License
/*
/********************************************************************************************/
/* This file implements elliptic curve over short weierstrass form, any coefficient a, with xyzz coordinates */
/* It is a custom 4 dimensional version of Shamir's trick (tis not a window)*/
/* (gen= any curve, sw=short weierstrass) */
/* b4=Four dimensional multiexponentiation */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import {_ModExpError} from "../include/SCL_errcodes.sol";

//kept for compatibility, the table now starts at the free memory pointer, which is never moved
uint256 constant _Prec_T8=0x800;
uint256 constant _Ap=0x820;
uint256 constant _y2=0x840;
uint256 constant _zzz2=0x860;
uint256 constant _free=0x880;

//mapping from Q in input to function, contains Qx, Qy, Qx', Qy', p, a, gx, gy, gx', gy'
//where P' is P multiplied by 2 pow 128 for shamir's multidimensional trick
uint constant _Qx=0x00;
uint constant _Qy=0x20;
uint constant _Qx2pow128=0x40;
uint constant _Qy2pow128=0x60;
uint constant _modp=0x80;
uint constant _a=0xa0;
uint constant _gx=0xc0;
uint constant _gy=0xe0;
uint constant _gpow2p128_x=0x100;
uint constant _gpow2p128_y=0x120;

//table index of the 11 points computed in XYZZ: G+G', G+Q, G'+Q, G+G'+Q, G+Q', G'+Q', G+G'+Q', Q+Q', G+Q+Q', G'+Q+Q', all
uint256 constant _DMAPB4=0x03050607090a0b0c0d0e0f000000000000000000000000000000000000000000;

/**
 * @dev uG+vQ in XYZZ coordinates with the 4-dimensional Shamir trick, Q = [Qx, Qy, Q'x, Q'y, p, a, gx, gy, g'x, g'y]
 *      where P' = 2^128.P. Returns (0, 0, 0, 0) when u = v = 0 or when the table is degenerate (weak key),
 *      otherwise ZZ = 0 iff the result is the point at infinity, Y being then nonzero for points of odd order.
 *      Q shall belong to the curve. Weak keys are the 16 values -P, -P128, -(P+P128), ... tested by ValidateKey.
 *      Uses the scratch space 0x00-0x3f and memory above the free memory pointer, which is not moved.
 */
function ecGenMulmuladdX_store_core(
        uint256 [10] memory Q,//store Qx, Qy, Q'x, Q'y p, a, gx, gy, gx2pow128, gy2pow128
        uint256 scalar_u,
        uint256 scalar_v
    )   view returns (uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ) {
        assembly ("memory-safe") {
            //halved generic doubling, output -2P (negated Y), uses 3/2 and a/2 stored at 0x00 and 0x20
            function dblNeg(x, y, zz, zzz, p) -> X3, Y3, ZZ3, ZZZ3 {
                let M := addmod(mulmod(mulmod(x, x, p), mload(0x00), p), mulmod(mulmod(zz, zz, p), mload(0x20), p), p)
                let V := mulmod(y, y, p)
                ZZZ3 := mulmod(mulmod(y, V, p), zzz, p)
                ZZ3 := mulmod(V, zz, p)
                let S := mulmod(x, V, p)
                X3 := addmod(mulmod(M, M, p), mulmod(sub(p, 2), S, p), p)
                Y3 := addmod(mulmod(V, V, p), mulmod(M, addmod(X3, sub(p, S), p), p), p)
            }
            //generic doubling of an affine point, output 2P in XYZZ
            function dblStd(x, y, p, a) -> X3, Y3, ZZ3, ZZZ3 {
                let U := addmod(y, y, p)
                ZZ3 := mulmod(U, U, p) //V
                ZZZ3 := mulmod(U, ZZ3, p) //W
                U := mulmod(x, ZZ3, p) //S
                let M := addmod(mulmod(3, mulmod(x, x, p), p), a, p)
                X3 := addmod(mulmod(M, M, p), mulmod(sub(p, 2), U, p), p)
                Y3 := addmod(mulmod(M, addmod(U, sub(p, X3), p), p), sub(p, mulmod(ZZZ3, y, p)), p)
            }
            //P1 (XYZZ) + P2 (affine); P1 = +/-P2 or P1 = O gives ZZZ3 = 0 (degenerate table, detected later)
            function addStd(x1, y1, zz1, zzz1, x2, y2, p) -> X3, Y3, ZZ3, ZZZ3 {
                x2 := addmod(mulmod(x2, zz1, p), sub(p, x1), p) //P
                y2 := addmod(mulmod(y2, zzz1, p), sub(p, y1), p) //R
                ZZ3 := mulmod(x2, x2, p) //PP
                ZZZ3 := mulmod(x2, ZZ3, p) //PPP
                x2 := mulmod(x1, ZZ3, p) //X1.PP
                X3 := addmod(addmod(mulmod(y2, y2, p), sub(p, ZZZ3), p), mulmod(sub(p, 2), x2, p), p)
                Y3 := addmod(mulmod(y2, addmod(x2, sub(p, X3), p), p), sub(p, mulmod(y1, ZZZ3, p)), p)
                ZZ3 := mulmod(zz1, ZZ3, p)
                ZZZ3 := mulmod(zzz1, ZZZ3, p)
            }
            function st4(ptr, x, y, p) {
                mstore(ptr, sub(p, x))
                mstore(add(ptr, 0x20), y)
                mstore(add(ptr, 0x40), sub(p, y))
                mstore(add(ptr, 0x60), x)
            }
            function stZ(ptr, x, y, zz, zzz) {
                mstore(ptr, x)
                mstore(add(ptr, 0x20), y)
                mstore(add(ptr, 0x40), zz)
                mstore(add(ptr, 0x60), zzz)
            }
            function dblSt(dst, x, y, p, a) {
                let ta, tb, tc, td := dblStd(x, y, p, a)
                stZ(dst, ta, tb, tc, td)
            }
            function addAff(dst, x1, y1, x2, y2, p) {
                let ta, tb, tc, td := addStd(x1, y1, 1, 1, x2, y2, p)
                stZ(dst, ta, tb, tc, td)
            }
            //dst = src (XYZZ in memory) + (x2, y2) affine
            function addSt(src, dst, x2, y2, p) {
                let ta, tb, tc, td :=
                    addStd(mload(src), mload(add(src, 0x20)), mload(add(src, 0x40)), mload(add(src, 0x60)), x2, y2, p)
                stZ(dst, ta, tb, tc, td)
            }
            //normalizes cnt XYZZ points stored at S0 with one modexp, entry k goes to table index byte(k, dmap)
            //returns 0 if one of the points is the point at infinity (degenerate table)
            function batchNorm(T, S0, cnt, dmap, p) -> ok {
                let PF := add(S0, shl(7, cnt))
                let ta := 1
                for { let k := 0 } lt(k, cnt) { k := add(k, 1) } {
                    ta := mulmod(ta, mload(add(S0, add(shl(7, k), 0x60))), p)
                    mstore(add(PF, shl(5, k)), ta)
                }
                ok := ta
                if ok {
                    let M0 := add(PF, shl(5, cnt))
                    mstore(M0, 0x20)
                    mstore(add(M0, 0x20), 0x20)
                    mstore(add(M0, 0x40), 0x20)
                    mstore(add(M0, 0x60), ta)
                    mstore(add(M0, 0x80), sub(p, 2))
                    mstore(add(M0, 0xa0), p)
                    if iszero(staticcall(gas(), 0x05, M0, 0xc0, M0, 0x20)) {
                        mstore(0x00, _ModExpError)
                        revert(0x00, 0x20)
                    }
                    ta := mload(M0)
                    for { let k := cnt } k {} {
                        k := sub(k, 1)
                        let pt := add(S0, shl(7, k))
                        let tb := ta
                        if k { tb := mulmod(ta, mload(add(PF, shl(5, sub(k, 1)))), p) }
                        ta := mulmod(ta, mload(add(pt, 0x60)), p)
                        let tc := mulmod(mload(add(pt, 0x40)), tb, p)
                        st4(
                            add(T, shl(7, byte(k, dmap))),
                            mulmod(mload(pt), mulmod(tc, tc, p), p),
                            mulmod(mload(add(pt, 0x20)), tb, p),
                            p
                        )
                    }
                }
            }
            //nibble k of the result = 2 bits k of u (low) and 2 bits k of v (high), u, v < 2^128
            function interleave(u, v) -> w {
                w := or(sp2(u), shl(2, sp2(v)))
            }
            function sp2(x) -> r {
                r := and(or(x, shl(64, x)), 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff)
                r := and(or(r, shl(32, r)), 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff)
                r := and(or(r, shl(16, r)), 0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff)
                r := and(or(r, shl(8, r)), 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff)
                r := and(or(r, shl(4, r)), 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f)
                r := and(or(r, shl(2, r)), 0x3333333333333333333333333333333333333333333333333333333333333333)
            }
            function modInvP(x, p) -> r {
                let M0 := mload(0x40)
                mstore(M0, 0x20)
                mstore(add(M0, 0x20), 0x20)
                mstore(add(M0, 0x40), 0x20)
                mstore(add(M0, 0x60), x)
                mstore(add(M0, 0x80), sub(p, 2))
                mstore(add(M0, 0xa0), p)
                if iszero(staticcall(gas(), 0x05, M0, 0xc0, M0, 0x20)) {
                    mstore(0x00, _ModExpError)
                    revert(0x00, 0x20)
                }
                r := mload(M0)
            }
            {
                let p := mload(add(Q, 0x80))
                let i2 := shr(1, add(p, 1)) // 1/2 mod p
                mstore(0x00, mulmod(3, i2, p))
                mstore(0x20, mulmod(mload(add(Q, 0xa0)), i2, p))
            }
            //nibble j = (bit sh+j of u, bit sh+128+j of u, bit sh+j of v, bit sh+128+j of v), j < 64
            function transp(u, v, sh) -> t {
                let m := 0xffffffffffffffff
                t :=
                    or(
                        or(spread4(and(shr(sh, u), m)), shl(1, spread4(and(shr(add(sh, 128), u), m)))),
                        or(shl(2, spread4(and(shr(sh, v), m))), shl(3, spread4(and(shr(add(sh, 128), v), m))))
                    )
            }
            function spread4(x) -> r {
                r := and(or(x, shl(96, x)), 0xffffffff000000000000000000000000ffffffff)
                r := and(or(r, shl(48, r)), 0xffff000000000000ffff000000000000ffff000000000000ffff)
                r := and(or(r, shl(24, r)), 0xff000000ff000000ff000000ff000000ff000000ff000000ff000000ff)
                r := and(or(r, shl(12, r)), 0xf000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f)
                r := and(or(r, shl(6, r)), 0x303030303030303030303030303030303030303030303030303030303030303)
                r := and(or(r, shl(3, r)), 0x1111111111111111111111111111111111111111111111111111111111111111)
            }
            /* I. table of the 15 sums of G, G'=2^128.G, Q, Q'=2^128.Q, bit 0 = G, bit 1 = G', bit 2 = Q, bit 3 = Q' */
            ZZZ := or(scalar_u, scalar_v)
            if ZZZ {
                let p := mload(add(Q, 0x80))
                let T := mload(0x40)
                let S0 := add(T, 0x800)
                st4(add(T, 0x80), mload(add(Q, 0xc0)), mload(add(Q, 0xe0)), p) // G
                st4(add(T, 0x100), mload(add(Q, 0x100)), mload(add(Q, 0x120)), p) // G'
                st4(add(T, 0x200), mload(Q), mload(add(Q, 0x20)), p) // Q
                st4(add(T, 0x400), mload(add(Q, 0x40)), mload(add(Q, 0x60)), p) // Q'
                addAff(S0, mload(add(Q, 0x100)), mload(add(Q, 0x120)), mload(add(Q, 0xc0)), mload(add(Q, 0xe0)), p) // G+G'
                addAff(add(S0, 0x80), mload(Q), mload(add(Q, 0x20)), mload(add(Q, 0xc0)), mload(add(Q, 0xe0)), p) // G+Q
                addAff(add(S0, 0x100), mload(Q), mload(add(Q, 0x20)), mload(add(Q, 0x100)), mload(add(Q, 0x120)), p) // G'+Q
                addAff(add(S0, 0x200), mload(add(Q, 0x40)), mload(add(Q, 0x60)), mload(add(Q, 0xc0)), mload(add(Q, 0xe0)), p) // G+Q'
                addAff(add(S0, 0x280), mload(add(Q, 0x40)), mload(add(Q, 0x60)), mload(add(Q, 0x100)), mload(add(Q, 0x120)), p) // G'+Q'
                addAff(add(S0, 0x380), mload(Q), mload(add(Q, 0x20)), mload(add(Q, 0x40)), mload(add(Q, 0x60)), p) // Q+Q'
                addSt(add(S0, 0x100), add(S0, 0x180), mload(add(Q, 0xc0)), mload(add(Q, 0xe0)), p) // G+G'+Q
                addSt(add(S0, 0x280), add(S0, 0x300), mload(add(Q, 0xc0)), mload(add(Q, 0xe0)), p) // G+G'+Q'
                addSt(add(S0, 0x380), add(S0, 0x400), mload(add(Q, 0xc0)), mload(add(Q, 0xe0)), p) // G+Q+Q'
                addSt(add(S0, 0x380), add(S0, 0x480), mload(add(Q, 0x100)), mload(add(Q, 0x120)), p) // G'+Q+Q'
                addSt(add(S0, 0x480), add(S0, 0x500), mload(add(Q, 0xc0)), mload(add(Q, 0xe0)), p) // G+G'+Q+Q'
                ZZZ := batchNorm(T, S0, 11, _DMAPB4, p) // ok flag
                mstore(T, eq(mload(add(Q, 0xa0)), sub(p, 3))) // a=-3 flag, in the unused entry 0
                mstore(add(T, 0x20), transp(scalar_u, scalar_v, 0)) // low nibbles, in the unused entry 0
                mstore(add(T, 0x40), 1) // low word pending
            }
            if ZZZ {
                /* II. main loop, one bit of the four 128-bit scalars per iteration
                   Stack: Q = current transposed word, scalar_u = nibble position, scalar_v = p */
                ZZZ := 0
                {
                    let p := mload(add(Q, 0x80))
                    Q := transp(scalar_u, scalar_v, 64)
                    scalar_v := p
                }
                if iszero(Q) {
                    Q := mload(add(mload(0x40), 0x20))
                    mstore(add(mload(0x40), 0x40), 0)
                }
                scalar_u := 252 // loop counter
                for {} iszero(shr(scalar_u, Q)) { scalar_u := sub(scalar_u, 4) } {}
                if mload(mload(0x40)) {
                    for {} 1 {} {
                        {
                            let M := mulmod(mulmod(addmod(X, sub(scalar_v, ZZ), scalar_v), addmod(X, ZZ, scalar_v), scalar_v), mload(0x00), scalar_v)
                            let V := mulmod(Y, Y, scalar_v)
                            ZZZ := mulmod(mulmod(Y, V, scalar_v), ZZZ, scalar_v)
                            ZZ := mulmod(V, ZZ, scalar_v)
                            let S := mulmod(X, V, scalar_v)
                            X := addmod(mulmod(M, M, scalar_v), mulmod(sub(scalar_v, 2), S, scalar_v), scalar_v)
                            Y := addmod(mulmod(V, V, scalar_v), mulmod(M, addmod(X, sub(scalar_v, S), scalar_v), scalar_v), scalar_v)
                        }
                        {
                            let e := and(shl(7, shr(scalar_u, Q)), 0x780)
                            switch e
                            case 0 { Y := sub(scalar_v, Y) }
                            default {
                                e := add(mload(0x40), e)
                                let Pn := addmod(mulmod(mload(e), ZZ, scalar_v), X, scalar_v)
                                let R := addmod(mulmod(mload(add(e, 0x20)), ZZZ, scalar_v), Y, scalar_v)
                                switch Pn
                                case 0 {
                                    switch ZZ
                                    case 0 {
                                        X := mload(add(e, 0x60))
                                        Y := mload(add(e, 0x20))
                                        ZZ := 1
                                        ZZZ := 1
                                    }
                                    default {
                                        switch R
                                        case 0 { X, Y, ZZ, ZZZ := dblNeg(X, Y, ZZ, ZZZ, scalar_v) }
                                        default {
                                            X := 0
                                            ZZ := 0
                                            ZZZ := 0
                                        }
                                    }
                                }
                                default {
                                    let PP := mulmod(Pn, Pn, scalar_v)
                                    Pn := mulmod(Pn, PP, scalar_v)
                                    ZZ := mulmod(ZZ, PP, scalar_v)
                                    ZZZ := mulmod(ZZZ, Pn, scalar_v)
                                    PP := mulmod(X, PP, scalar_v)
                                    X := addmod(addmod(mulmod(R, R, scalar_v), Pn, scalar_v), mulmod(sub(scalar_v, 2), PP, scalar_v), scalar_v)
                                    Y := addmod(mulmod(R, addmod(X, sub(scalar_v, PP), scalar_v), scalar_v), mulmod(Y, Pn, scalar_v), scalar_v)
                                }
                            }
                        }
                        if iszero(scalar_u) {
                            if iszero(mload(add(mload(0x40), 0x40))) { break }
                            Q := mload(add(mload(0x40), 0x20))
                            mstore(add(mload(0x40), 0x40), 0)
                            scalar_u := 256
                        }
                        scalar_u := sub(scalar_u, 4)
                    }
                }
                if iszero(mload(mload(0x40))) {
                    for {} 1 {} {
                        {
                            let M := addmod(mulmod(mulmod(X, X, scalar_v), mload(0x00), scalar_v), mulmod(mulmod(ZZ, ZZ, scalar_v), mload(0x20), scalar_v), scalar_v)
                            let V := mulmod(Y, Y, scalar_v)
                            ZZZ := mulmod(mulmod(Y, V, scalar_v), ZZZ, scalar_v)
                            ZZ := mulmod(V, ZZ, scalar_v)
                            let S := mulmod(X, V, scalar_v)
                            X := addmod(mulmod(M, M, scalar_v), mulmod(sub(scalar_v, 2), S, scalar_v), scalar_v)
                            Y := addmod(mulmod(V, V, scalar_v), mulmod(M, addmod(X, sub(scalar_v, S), scalar_v), scalar_v), scalar_v)
                        }
                        {
                            let e := and(shl(7, shr(scalar_u, Q)), 0x780)
                            switch e
                            case 0 { Y := sub(scalar_v, Y) }
                            default {
                                e := add(mload(0x40), e)
                                let Pn := addmod(mulmod(mload(e), ZZ, scalar_v), X, scalar_v)
                                let R := addmod(mulmod(mload(add(e, 0x20)), ZZZ, scalar_v), Y, scalar_v)
                                switch Pn
                                case 0 {
                                    switch ZZ
                                    case 0 {
                                        X := mload(add(e, 0x60))
                                        Y := mload(add(e, 0x20))
                                        ZZ := 1
                                        ZZZ := 1
                                    }
                                    default {
                                        switch R
                                        case 0 { X, Y, ZZ, ZZZ := dblNeg(X, Y, ZZ, ZZZ, scalar_v) }
                                        default {
                                            X := 0
                                            ZZ := 0
                                            ZZZ := 0
                                        }
                                    }
                                }
                                default {
                                    let PP := mulmod(Pn, Pn, scalar_v)
                                    Pn := mulmod(Pn, PP, scalar_v)
                                    ZZ := mulmod(ZZ, PP, scalar_v)
                                    ZZZ := mulmod(ZZZ, Pn, scalar_v)
                                    PP := mulmod(X, PP, scalar_v)
                                    X := addmod(addmod(mulmod(R, R, scalar_v), Pn, scalar_v), mulmod(sub(scalar_v, 2), PP, scalar_v), scalar_v)
                                    Y := addmod(mulmod(R, addmod(X, sub(scalar_v, PP), scalar_v), scalar_v), mulmod(Y, Pn, scalar_v), scalar_v)
                                }
                            }
                        }
                        if iszero(scalar_u) {
                            if iszero(mload(add(mload(0x40), 0x40))) { break }
                            Q := mload(add(mload(0x40), 0x20))
                            mstore(add(mload(0x40), 0x40), 0)
                            scalar_u := 256
                        }
                        scalar_u := sub(scalar_u, 4)
                    }
                }
            }
        }
}

/**
 * @dev x coordinate of uG+vQ, 0 for the point at infinity, for u = v = 0 and for weak keys.
 *      Q = [Qx, Qy, Q'x, Q'y, p, a, gx, gy, g'x, g'y], P' = 2^128.P
 */
function ecGenMulmuladdX_store(
        uint256 [10] memory Q,//store Qx, Qy, Q'x, Q'y p, a, gx, gy, gx2pow128, gy2pow128
        uint256 scalar_u,
        uint256 scalar_v
    )   view returns (uint256 X) {
        uint256 ZZ;
        (X, , ZZ, ) = ecGenMulmuladdX_store_core(Q, scalar_u, scalar_v);
        assembly ("memory-safe") {
            if ZZ {
                let p := mload(add(Q, 0x80))
                let M0 := mload(0x40)
                mstore(M0, 0x20)
                mstore(add(M0, 0x20), 0x20)
                mstore(add(M0, 0x40), 0x20)
                mstore(add(M0, 0x60), ZZ)
                mstore(add(M0, 0x80), sub(p, 2))
                mstore(add(M0, 0xa0), p)
                if iszero(staticcall(gas(), 0x05, M0, 0xc0, M0, 0x20)) {
                    mstore(0x00, _ModExpError)
                    revert(0x00, 0x20)
                }
                X := mulmod(X, mload(M0), p) //X/ZZ
            }
        }
}
