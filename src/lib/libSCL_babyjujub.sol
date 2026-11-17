/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)
/* Description: raw verification of circomlib EdDSA signatures on BabyJubJub, S.B8 == R8 + 8.hm.A,
/* the challenge hm being already hashed (Poseidon, MiMC7, MiMCSponge or Pedersen in circomlib).
/* The scalar multiplications run on the isomorphic short Weierstrass curve with a = -3
/* (src/fields/SCL_babyjujub.sol), as ed25519 runs on Wei25519.
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import {
    p, a, b, n, gx, gy, gpow2p128_x, gpow2p128_y, ED_A, ED_D, MU2, MU3, A3MU2, IMU2, IMU3,
    _SMALL1_X, _SMALL1_Y, _SMALL1_C, _SMALL2_X, _SMALL2_Y, _SMALL2_C, _SMALL3_X, _SMALL3_Y, _SMALL3_C,
    _SMALL4_X, _SMALL4_Y, _SMALL4_C, _SMALL5_X, _SMALL5_Y, _SMALL5_C, _SMALL6_X, _SMALL6_Y, _SMALL6_C,
    _SMALL7_X, _SMALL7_Y, _SMALL7_C
} from "@solidity/fields/SCL_babyjujub.sol";
import {ecGenMulmuladdB4W_core} from "@solidity/elliptic/SCL_mulmuladdX_fullgenW.sol";
import {ecGenMulmuladdX_store_core} from "@solidity/elliptic/SCL_mulmuladdX_fullgen_b4.sol";
import {ModInv} from "@solidity/modular/SCL_modular.sol";

/**
 * Key formats, A being the circomlib public key (twisted Edwards, affine):
 *  - verifyRaw:   A,
 *  - verifyRawW:  W8 = pubKeyToW8(A), image of 8A on the Weierstrass curve, (0,0) if 8A is the neutral point,
 *  - verifyRawB4: [W8, 2^128.W8] = pubKeyToW8B4(A), for the 4-dimensional multiplication (fastest).
 * Same acceptance as circomlibjs verifyPoseidon/MiMC/Pedersen: A and R8 on the curve, S < subOrder,
 * hm taken modulo the subgroup order (8A has order 1 or l).
 */
library SCL_BABYJUJUB {
    /// @dev twisted Edwards membership, coordinates must be reduced
    function ed_isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        if (x >= p || y >= p) return false;
        uint256 x2 = mulmod(x, x, p);
        uint256 y2 = mulmod(y, y, p);
        return addmod(mulmod(ED_A, x2, p), y2, p) == addmod(1, mulmod(ED_D, mulmod(x2, y2, p), p), p);
    }

    /// @dev short Weierstrass (a = -3) membership
    function ecAff_isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        if (x >= p || y >= p) return false;
        return mulmod(y, y, p) == addmod(mulmod(addmod(mulmod(x, x, p), a, p), x, p), b, p);
    }

    /// @dev Edwards affine -> Weierstrass affine, (0,1) (neutral) is mapped to (0,0)
    function ed2W(uint256 x, uint256 y) internal view returns (uint256 X, uint256 Y) {
        if (x == 0) {
            if (y == 1) return (0, 0);
            return (A3MU2, 0); // (0,-1), 2-torsion point
        }
        uint256 om = addmod(1, p - y, p);
        uint256 inv = ModInv(mulmod(om, x, p), p); // 1/((1-y)x)
        uint256 op = addmod(1, y, p);
        X = addmod(mulmod(MU2, mulmod(op, mulmod(inv, x, p), p), p), A3MU2, p);
        Y = mulmod(MU3, mulmod(op, inv, p), p);
    }

    /// @dev Weierstrass affine -> Edwards affine, (0,0) is read as the neutral point
    function W2ed(uint256 X, uint256 Y) internal view returns (uint256 x, uint256 y) {
        if (X == 0 && Y == 0) return (0, 1);
        if (Y == 0) return (0, p - 1);
        uint256 u = mulmod(addmod(X, p - A3MU2, p), IMU2, p);
        uint256 v = mulmod(Y, IMU3, p);
        // x = u/v, y = (u-1)/(u+1), one inversion
        uint256 up1 = addmod(u, 1, p);
        uint256 inv = ModInv(mulmod(v, up1, p), p);
        x = mulmod(mulmod(u, up1, p), inv, p);
        y = mulmod(mulmod(addmod(u, p - 1, p), v, p), inv, p);
    }

    /// @dev 2^k.(X:Y:Z), projective twisted Edwards doublings (dbl-2008-bbjlp, complete on BabyJubJub)
    function edDblN(uint256 X, uint256 Y, uint256 Z, uint256 k) internal pure returns (uint256, uint256, uint256) {
        assembly ("memory-safe") {
            for {} k { k := sub(k, 1) } {
                let B := mulmod(add(X, Y), add(X, Y), p)
                let C := mulmod(X, X, p)
                let D := mulmod(Y, Y, p)
                let E := mulmod(ED_A, C, p)
                let F := addmod(E, D, p)
                let J := addmod(F, sub(p, mulmod(2, mulmod(Z, Z, p), p)), p)
                X := mulmod(addmod(B, sub(p, addmod(C, D, p)), p), J, p)
                Y := mulmod(F, addmod(E, sub(p, D), p), p)
                Z := mulmod(F, J, p)
            }
        }
        return (X, Y, Z);
    }

    /**
     * @dev 8.A on the Weierstrass curve, key format of verifyRawW (precompute once per key).
     *      A must be on the Edwards curve. Returns (0,0) when 8A is the neutral point (small order key).
     */
    function pubKeyToW8(uint256 Ax, uint256 Ay) internal view returns (uint256 Wx, uint256 Wy) {
        (uint256 X, uint256 Y, uint256 Z) = edDblN(Ax, Ay, 1, 3);
        if (X == 0) return (0, 0);
        // mu^2 (Z+Y)/(Z-Y) + mu^2 A/3, mu^3 (Z+Y)Z/((Z-Y)X), one inversion
        uint256 zp = addmod(Z, Y, p);
        uint256 inv = ModInv(mulmod(addmod(Z, p - Y, p), X, p), p);
        Wx = addmod(mulmod(MU2, mulmod(mulmod(zp, X, p), inv, p), p), A3MU2, p);
        Wy = mulmod(MU3, mulmod(mulmod(zp, Z, p), inv, p), p);
    }

    /**
     * @dev [W8, 2^128.W8] on the Weierstrass curve, key format of verifyRawB4 (precompute once per key):
     *      131 Edwards doublings, both points mapped with one inversion.
     *      A must be on the Edwards curve. Returns zeros when 8A is the neutral point.
     */
    function pubKeyToW8B4(uint256 Ax, uint256 Ay) internal view returns (uint256[4] memory W) {
        (uint256 X, uint256 Y, uint256 Z) = edDblN(Ax, Ay, 1, 3);
        if (X == 0) return W;
        (uint256 X2, uint256 Y2, uint256 Z2) = edDblN(X, Y, Z, 128);
        uint256 d1 = mulmod(addmod(Z, p - Y, p), X, p);
        uint256 d2 = mulmod(addmod(Z2, p - Y2, p), X2, p);
        uint256 inv = ModInv(mulmod(d1, d2, p), p);
        d1 = mulmod(inv, d1, p); // 1/d2
        d2 = mulmod(inv, d2, p); // 1/d1
        uint256 zp = addmod(Z, Y, p);
        W[0] = addmod(mulmod(MU2, mulmod(mulmod(zp, X, p), d2, p), p), A3MU2, p);
        W[1] = mulmod(MU3, mulmod(mulmod(zp, Z, p), d2, p), p);
        zp = addmod(Z2, Y2, p);
        W[2] = addmod(mulmod(MU2, mulmod(mulmod(zp, X2, p), d1, p), p), A3MU2, p);
        W[3] = mulmod(MU3, mulmod(mulmod(zp, Z2, p), d1, p), p);
    }

    /**
     * @dev Keys Q = +/-c.G with c in {1, 2, 3, 1/2, 3/2, 1/3, 2/3} (mod n) make some entries of the table of
     *      ecGenMulmuladdB4W degenerate, the multiplication is then rewritten as (u + c.v).G. Returns c, or 0.
     */
    function smallMultipleOfG(uint256 Qx, uint256 Qy) internal pure returns (uint256 c) {
        assembly ("memory-safe") {
            let y
            if eq(Qx, _SMALL1_X) {
                c := _SMALL1_C
                y := _SMALL1_Y
            }
            if eq(Qx, _SMALL2_X) {
                c := _SMALL2_C
                y := _SMALL2_Y
            }
            if eq(Qx, _SMALL3_X) {
                c := _SMALL3_C
                y := _SMALL3_Y
            }
            if eq(Qx, _SMALL4_X) {
                c := _SMALL4_C
                y := _SMALL4_Y
            }
            if eq(Qx, _SMALL5_X) {
                c := _SMALL5_C
                y := _SMALL5_Y
            }
            if eq(Qx, _SMALL6_X) {
                c := _SMALL6_C
                y := _SMALL6_Y
            }
            if eq(Qx, _SMALL7_X) {
                c := _SMALL7_C
                y := _SMALL7_Y
            }
            if c { if iszero(eq(Qy, y)) { c := sub(n, c) } }
        }
    }

    /**
     * @dev uG+vQ in XYZZ coordinates (ZZ == 0 iff point at infinity) with the joint 2-bit window,
     *      for any key of the curve including the weak ones, Q = (0,0) read as the point at infinity.
     */
    function ecMulmuladdW(uint256 Qx, uint256 Qy, uint256 u, uint256 v)
        internal
        view
        returns (uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ)
    {
        if (v != 0) {
            uint256 c = smallMultipleOfG(Qx, Qy);
            if (c != 0) {
                u = addmod(u, mulmod(c, v, n), n);
                v = 0;
            }
        }
        uint256[6] memory Q = [Qx, Qy, p, a, gx, gy];
        return ecGenMulmuladdB4W_core(Q, u, v);
    }

    /// @dev uG+vQ in Weierstrass affine coordinates, (0,0) for the point at infinity
    function ecMulmuladd(uint256 Qx, uint256 Qy, uint256 u, uint256 v) internal view returns (uint256 X, uint256 Y) {
        uint256 ZZ;
        uint256 ZZZ;
        (X, Y, ZZ, ZZZ) = ecMulmuladdW(Qx, Qy, u, v);
        if (ZZ == 0) return (0, 0);
        ZZZ = ModInv(ZZZ, p);
        Y = mulmod(Y, ZZZ, p); //Y/ZZZ
        ZZ = mulmod(ZZ, ZZZ, p); //1/Z
        X = mulmod(X, mulmod(ZZ, ZZ, p), p); //X/ZZ
    }

    /**
     * @dev R8 == (X/ZZ, Y/ZZZ) mapped to Edwards, compared in projective coordinates (no inversion).
     *      R8 shall be on the Edwards curve. R8 = (0,1) matches the point at infinity (ZZ == 0) only.
     */
    function eqR8(uint256 R8x, uint256 R8y, uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ)
        internal
        pure
        returns (bool ok)
    {
        assembly ("memory-safe") {
            let om := addmod(1, sub(p, R8y), p) // 1-y
            switch om
            case 0 { ok := iszero(ZZ) }
            default {
                let op := addmod(1, R8y, p) // 1+y
                // X/ZZ == (MU2(1+y) + A3MU2(1-y))/(1-y)
                let t := mulmod(addmod(mulmod(MU2, op, p), mulmod(A3MU2, om, p), p), ZZ, p)
                ok := and(iszero(iszero(ZZ)), eq(mulmod(X, om, p), t))
                // Y/ZZZ == MU3(1+y)/((1-y)x)
                t := mulmod(mulmod(MU3, op, p), ZZZ, p)
                ok := and(ok, eq(mulmod(mulmod(Y, om, p), R8x, p), t))
            }
        }
    }

    /**
     * @dev Raw circomlib EdDSA check S.B8 == R8 + 8.hm.A, the key given as W8 = pubKeyToW8(A).
     *      Joint 2-bit window, one modular inversion (the table).
     */
    function verifyRawW(uint256 hm, uint256 R8x, uint256 R8y, uint256 S, uint256 Wx, uint256 Wy)
        internal
        view
        returns (bool)
    {
        if (S >= n || !ed_isOnCurve(R8x, R8y)) return false;
        if ((Wx | Wy) != 0 && !ecAff_isOnCurve(Wx, Wy)) return false;
        // S.G - hm.W8, result (X, Y, ZZ, ZZZ) stored in (Wx, Wy, hm, S)
        (Wx, Wy, hm, S) = ecMulmuladdW(Wx, Wy, S, addmod(n - hm % n, 0, n));
        return eqR8(R8x, R8y, Wx, Wy, hm, S);
    }

    /**
     * @dev Raw circomlib EdDSA check S.B8 == R8 + 8.hm.A, the key given as [W8, 2^128.W8] = pubKeyToW8B4(A).
     *      4-dimensional Shamir trick, one modular inversion (the table). Keys with a degenerate table and
     *      the small order keys fall back to verifyRawW.
     */
    function verifyRawB4(uint256 hm, uint256 R8x, uint256 R8y, uint256 S, uint256[4] memory W)
        internal
        view
        returns (bool)
    {
        if ((W[0] | W[1]) == 0) return verifyRawW(hm, R8x, R8y, S, 0, 0);
        if (S >= n || !ed_isOnCurve(R8x, R8y) || !ecAff_isOnCurve(W[0], W[1])) return false;
        uint256 res = checkB4(R8x, R8y, [W[0], W[1], W[2], W[3], p, a, gx, gy, gpow2p128_x, gpow2p128_y], S, addmod(n - hm % n, 0, n));
        if (res == 2) return verifyRawW(hm, R8x, R8y, S, W[0], W[1]); // weak key, or S = hm = 0 mod n
        return res == 1;
    }

    /// @dev uG+vQ == R8 with the 4-dim engine: 1 true, 0 false, 2 degenerate table or u = v = 0
    function checkB4(uint256 R8x, uint256 R8y, uint256[10] memory Q, uint256 u, uint256 v)
        internal
        view
        returns (uint256)
    {
        (uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ) = ecGenMulmuladdX_store_core(Q, u, v);
        if ((Y | ZZ) == 0) return 2;
        return eqR8(R8x, R8y, X, Y, ZZ, ZZZ) ? 1 : 0;
    }

    /**
     * @dev Raw circomlib EdDSA check S.B8 == R8 + 8.hm.A with A in circomlib (Edwards) coordinates.
     *      Same input checks as circomlibjs: A and R8 on the curve, S < subOrder.
     */
    function verifyRaw(uint256 hm, uint256 R8x, uint256 R8y, uint256 S, uint256 Ax, uint256 Ay)
        internal
        view
        returns (bool)
    {
        if (!ed_isOnCurve(Ax, Ay)) return false;
        (uint256 Wx, uint256 Wy) = pubKeyToW8(Ax, Ay);
        return verifyRawW(hm, R8x, R8y, S, Wx, Wy);
    }
}
