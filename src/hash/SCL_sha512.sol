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

// SPDX-License-Identifier: MIT

//https://emn178.github.io/online-tools/sha512.html

pragma solidity >=0.8.19 <0.9.0;

import "../../external/sha512/Sha2Ext.sol";

library SCL_sha512 {
 
    /**
     * @dev SHA-512 of a memory byte array, same output as Sha2Ext.sha512 (two big endian halves).
     *      Uses memory above the free memory pointer as scratch, the pointer is not moved.
     *      Layout from the free memory pointer: K, W, K+W (80 words each), saved state (8 words), padded message.
     */
    function sha512(bytes memory message) internal pure returns (bytes32 high, bytes32 low) {
        assembly ("memory-safe") {
            high := mload(0x40) // base of the scratch area
            mstore(add(high, 0x0), 0x428a2f98d728ae22)
            mstore(add(high, 0x20), 0x7137449123ef65cd)
            mstore(add(high, 0x40), 0xb5c0fbcfec4d3b2f)
            mstore(add(high, 0x60), 0xe9b5dba58189dbbc)
            mstore(add(high, 0x80), 0x3956c25bf348b538)
            mstore(add(high, 0xa0), 0x59f111f1b605d019)
            mstore(add(high, 0xc0), 0x923f82a4af194f9b)
            mstore(add(high, 0xe0), 0xab1c5ed5da6d8118)
            mstore(add(high, 0x100), 0xd807aa98a3030242)
            mstore(add(high, 0x120), 0x12835b0145706fbe)
            mstore(add(high, 0x140), 0x243185be4ee4b28c)
            mstore(add(high, 0x160), 0x550c7dc3d5ffb4e2)
            mstore(add(high, 0x180), 0x72be5d74f27b896f)
            mstore(add(high, 0x1a0), 0x80deb1fe3b1696b1)
            mstore(add(high, 0x1c0), 0x9bdc06a725c71235)
            mstore(add(high, 0x1e0), 0xc19bf174cf692694)
            mstore(add(high, 0x200), 0xe49b69c19ef14ad2)
            mstore(add(high, 0x220), 0xefbe4786384f25e3)
            mstore(add(high, 0x240), 0xfc19dc68b8cd5b5)
            mstore(add(high, 0x260), 0x240ca1cc77ac9c65)
            mstore(add(high, 0x280), 0x2de92c6f592b0275)
            mstore(add(high, 0x2a0), 0x4a7484aa6ea6e483)
            mstore(add(high, 0x2c0), 0x5cb0a9dcbd41fbd4)
            mstore(add(high, 0x2e0), 0x76f988da831153b5)
            mstore(add(high, 0x300), 0x983e5152ee66dfab)
            mstore(add(high, 0x320), 0xa831c66d2db43210)
            mstore(add(high, 0x340), 0xb00327c898fb213f)
            mstore(add(high, 0x360), 0xbf597fc7beef0ee4)
            mstore(add(high, 0x380), 0xc6e00bf33da88fc2)
            mstore(add(high, 0x3a0), 0xd5a79147930aa725)
            mstore(add(high, 0x3c0), 0x6ca6351e003826f)
            mstore(add(high, 0x3e0), 0x142929670a0e6e70)
            mstore(add(high, 0x400), 0x27b70a8546d22ffc)
            mstore(add(high, 0x420), 0x2e1b21385c26c926)
            mstore(add(high, 0x440), 0x4d2c6dfc5ac42aed)
            mstore(add(high, 0x460), 0x53380d139d95b3df)
            mstore(add(high, 0x480), 0x650a73548baf63de)
            mstore(add(high, 0x4a0), 0x766a0abb3c77b2a8)
            mstore(add(high, 0x4c0), 0x81c2c92e47edaee6)
            mstore(add(high, 0x4e0), 0x92722c851482353b)
            mstore(add(high, 0x500), 0xa2bfe8a14cf10364)
            mstore(add(high, 0x520), 0xa81a664bbc423001)
            mstore(add(high, 0x540), 0xc24b8b70d0f89791)
            mstore(add(high, 0x560), 0xc76c51a30654be30)
            mstore(add(high, 0x580), 0xd192e819d6ef5218)
            mstore(add(high, 0x5a0), 0xd69906245565a910)
            mstore(add(high, 0x5c0), 0xf40e35855771202a)
            mstore(add(high, 0x5e0), 0x106aa07032bbd1b8)
            mstore(add(high, 0x600), 0x19a4c116b8d2d0c8)
            mstore(add(high, 0x620), 0x1e376c085141ab53)
            mstore(add(high, 0x640), 0x2748774cdf8eeb99)
            mstore(add(high, 0x660), 0x34b0bcb5e19b48a8)
            mstore(add(high, 0x680), 0x391c0cb3c5c95a63)
            mstore(add(high, 0x6a0), 0x4ed8aa4ae3418acb)
            mstore(add(high, 0x6c0), 0x5b9cca4f7763e373)
            mstore(add(high, 0x6e0), 0x682e6ff3d6b2b8a3)
            mstore(add(high, 0x700), 0x748f82ee5defb2fc)
            mstore(add(high, 0x720), 0x78a5636f43172f60)
            mstore(add(high, 0x740), 0x84c87814a1f0ab72)
            mstore(add(high, 0x760), 0x8cc702081a6439ec)
            mstore(add(high, 0x780), 0x90befffa23631e28)
            mstore(add(high, 0x7a0), 0xa4506cebde82bde9)
            mstore(add(high, 0x7c0), 0xbef9a3f7b2c67915)
            mstore(add(high, 0x7e0), 0xc67178f2e372532b)
            mstore(add(high, 0x800), 0xca273eceea26619c)
            mstore(add(high, 0x820), 0xd186b8c721c0c207)
            mstore(add(high, 0x840), 0xeada7dd6cde0eb1e)
            mstore(add(high, 0x860), 0xf57d4f7fee6ed178)
            mstore(add(high, 0x880), 0x6f067aa72176fba)
            mstore(add(high, 0x8a0), 0xa637dc5a2c898a6)
            mstore(add(high, 0x8c0), 0x113f9804bef90dae)
            mstore(add(high, 0x8e0), 0x1b710b35131c471b)
            mstore(add(high, 0x900), 0x28db77f523047d84)
            mstore(add(high, 0x920), 0x32caab7b40c72493)
            mstore(add(high, 0x940), 0x3c9ebe0a15c9bebc)
            mstore(add(high, 0x960), 0x431d67c49c100d4c)
            mstore(add(high, 0x980), 0x4cc5d4becb3e42b6)
            mstore(add(high, 0x9a0), 0x597f299cfc657e2a)
            mstore(add(high, 0x9c0), 0x5fcb6fab3ad6faec)
            mstore(add(high, 0x9e0), 0x6c44198c4a475817)
            {
                let len := mload(message)
                let buf := add(high, 0x1f00)
                let n := shl(7, shr(7, add(len, 0x90))) // padded length, multiple of 128
                for { let i := 0 } lt(i, n) { i := add(i, 0x20) } { mstore(add(buf, i), 0) }
                for { let i := 0 } lt(i, len) { i := add(i, 0x20) } { mstore(add(buf, i), mload(add(message, add(0x20, i)))) }
                if and(len, 0x1f) {
                    let pt := add(buf, and(len, not(0x1f)))
                    mstore(pt, and(mload(pt), not(shr(shl(3, and(len, 0x1f)), not(0)))))
                }
                mstore8(add(buf, len), 0x80)
                let pt := add(buf, sub(n, 0x20))
                mstore(pt, or(and(mload(pt), not(0xffffffffffffffffffffffffffffffff)), shl(3, len)))
                message := buf // first block
                low := add(buf, n) // end of the padded message
            }
            let a := 0x6a09e667f3bcc908
            let b := 0xbb67ae8584caa73b
            let c := 0x3c6ef372fe94f82b
            let d := 0xa54ff53a5f1d36f1
            let e := 0x510e527fade682d1
            let f := 0x9b05688c2b3e6c1f
            let g := 0x1f83d9abfb41bd6b
            let h := 0x5be0cd19137e2179
            for {} lt(message, low) { message := add(message, 0x80) } {
                // message schedule: W[t] at high+0xa00, K[t]+W[t] at high+0x1400
                for { let t := 0 } lt(t, 0x200) { t := add(t, 0x80) } {
                    let x := mload(add(message, shr(2, t)))
                    let o := add(add(high, 0xa00), t)
                    mstore(o, shr(192, x))
                    mstore(add(o, 0xa00), add(shr(192, x), mload(add(high, t))))
                    mstore(add(o, 0x20), and(shr(128, x), 0xffffffffffffffff))
                    mstore(add(o, 0xa20), add(and(shr(128, x), 0xffffffffffffffff), mload(add(high, add(t, 0x20)))))
                    mstore(add(o, 0x40), and(shr(64, x), 0xffffffffffffffff))
                    mstore(add(o, 0xa40), add(and(shr(64, x), 0xffffffffffffffff), mload(add(high, add(t, 0x40)))))
                    mstore(add(o, 0x60), and(x, 0xffffffffffffffff))
                    mstore(add(o, 0xa60), add(and(x, 0xffffffffffffffff), mload(add(high, add(t, 0x60)))))
                }
                for { let t := add(high, 0xc00) } lt(t, add(high, 0x1400)) { t := add(t, 0x20) } {
                    let w := mload(sub(t, 0x40))
                    let x := or(w, shl(64, w))
                    w := add(xor(xor(shr(19, x), shr(61, x)), shr(6, w)), mload(sub(t, 0xe0)))
                    x := mload(sub(t, 0x1e0))
                    w := add(w, add(xor(xor(shr(1, or(x, shl(64, x))), shr(8, or(x, shl(64, x)))), shr(7, x)), mload(sub(t, 0x200))))
                    w := and(w, 0xffffffffffffffff)
                    mstore(t, w)
                    mstore(add(t, 0xa00), add(w, mload(sub(t, 0xa00))))
                }
                // save the state for the feed-forward
                mstore(add(high, 0x1e00), a)
                mstore(add(high, 0x1e20), b)
                mstore(add(high, 0x1e40), c)
                mstore(add(high, 0x1e60), d)
                mstore(add(high, 0x1e80), e)
                mstore(add(high, 0x1ea0), f)
                mstore(add(high, 0x1ec0), g)
                mstore(add(high, 0x1ee0), h)
                // 80 rounds, 8 per iteration
                for { let kw := add(high, 0x1400) } lt(kw, add(high, 0x1e00)) { kw := add(kw, 0x100) } {
                    {
                        let x := or(e, shl(64, e))
                        h := add(add(h, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor(g, and(e, xor(f, g))), mload(add(kw, 0x0))))
                        d := and(add(d, h), 0xffffffffffffffff)
                        x := or(a, shl(64, a))
                        h := and(add(h, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and(a, b), and(c, or(a, b))))), 0xffffffffffffffff)
                    }
                    {
                        let x := or(d, shl(64, d))
                        g := add(add(g, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor(f, and(d, xor(e, f))), mload(add(kw, 0x20))))
                        c := and(add(c, g), 0xffffffffffffffff)
                        x := or(h, shl(64, h))
                        g := and(add(g, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and(h, a), and(b, or(h, a))))), 0xffffffffffffffff)
                    }
                    {
                        let x := or(c, shl(64, c))
                        f := add(add(f, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor(e, and(c, xor(d, e))), mload(add(kw, 0x40))))
                        b := and(add(b, f), 0xffffffffffffffff)
                        x := or(g, shl(64, g))
                        f := and(add(f, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and(g, h), and(a, or(g, h))))), 0xffffffffffffffff)
                    }
                    {
                        let x := or(b, shl(64, b))
                        e := add(add(e, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor(d, and(b, xor(c, d))), mload(add(kw, 0x60))))
                        a := and(add(a, e), 0xffffffffffffffff)
                        x := or(f, shl(64, f))
                        e := and(add(e, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and(f, g), and(h, or(f, g))))), 0xffffffffffffffff)
                    }
                    {
                        let x := or(a, shl(64, a))
                        d := add(add(d, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor(c, and(a, xor(b, c))), mload(add(kw, 0x80))))
                        h := and(add(h, d), 0xffffffffffffffff)
                        x := or(e, shl(64, e))
                        d := and(add(d, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and(e, f), and(g, or(e, f))))), 0xffffffffffffffff)
                    }
                    {
                        let x := or(h, shl(64, h))
                        c := add(add(c, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor(b, and(h, xor(a, b))), mload(add(kw, 0xa0))))
                        g := and(add(g, c), 0xffffffffffffffff)
                        x := or(d, shl(64, d))
                        c := and(add(c, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and(d, e), and(f, or(d, e))))), 0xffffffffffffffff)
                    }
                    {
                        let x := or(g, shl(64, g))
                        b := add(add(b, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor(a, and(g, xor(h, a))), mload(add(kw, 0xc0))))
                        f := and(add(f, b), 0xffffffffffffffff)
                        x := or(c, shl(64, c))
                        b := and(add(b, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and(c, d), and(e, or(c, d))))), 0xffffffffffffffff)
                    }
                    {
                        let x := or(f, shl(64, f))
                        a := add(add(a, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor(h, and(f, xor(g, h))), mload(add(kw, 0xe0))))
                        e := and(add(e, a), 0xffffffffffffffff)
                        x := or(b, shl(64, b))
                        a := and(add(a, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and(b, c), and(d, or(b, c))))), 0xffffffffffffffff)
                    }
                }
                a := and(add(a, mload(add(high, 0x1e00))), 0xffffffffffffffff)
                b := and(add(b, mload(add(high, 0x1e20))), 0xffffffffffffffff)
                c := and(add(c, mload(add(high, 0x1e40))), 0xffffffffffffffff)
                d := and(add(d, mload(add(high, 0x1e60))), 0xffffffffffffffff)
                e := and(add(e, mload(add(high, 0x1e80))), 0xffffffffffffffff)
                f := and(add(f, mload(add(high, 0x1ea0))), 0xffffffffffffffff)
                g := and(add(g, mload(add(high, 0x1ec0))), 0xffffffffffffffff)
                h := and(add(h, mload(add(high, 0x1ee0))), 0xffffffffffffffff)
            }
            high := or(or(shl(192, a), shl(128, b)), or(shl(64, c), d))
            low := or(or(shl(192, e), shl(128, f)), or(shl(64, g), h))
        }
    }

    function Swap512(uint256[2] memory w) internal pure returns(uint256[2] memory r)
    {
        r[0]=Swap256(w[1]);
        r[1]=Swap256(w[0]);

        return r;
    }

    function Swap256(uint256 w) internal pure returns (uint256 x)
    {
        return uint256(Swap128(uint128(w>>128)))^(uint256(Swap128(uint128(w&0xffffffffffffffffffffffffffffffff)))<<128);
    }

    function Swap128(uint128 w) internal pure returns (uint128 x)
    {
        return uint128(Swap64(uint64(w>>64)))^(uint128(Swap64(uint64(w&0xffffffffffffffff)))<<64);
    }


    function Swap64(uint64 w) internal pure returns (uint64 x){
     uint64 tmp= (w >> 32) | (w << 32);
	 tmp = ((tmp & 0xff00ff00ff00ff00) >> 8) |    ((tmp & 0x00ff00ff00ff00ff) << 8); 
	 x = ((tmp & 0xffff0000ffff0000) >> 16) |   ((tmp & 0x0000ffff0000ffff) << 16); 
    }

}