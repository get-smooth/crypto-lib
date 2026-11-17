// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

// Raw circomlib EdDSA verification on BabyJubJub (SCL_BABYJUJUB): isomorphism, key precomputation against the
// python oracle (test/gen/bjj_vec.py), circomlibjs signatures (test/gen/gen_vectors.mjs), weak keys of both
// tables, random consistency, gas.

import "forge-std/Test.sol";

import {SCL_BABYJUJUB as BJJ} from "@solidity/lib/libSCL_babyjujub.sol";
import {
    p, a, n, gx, gy, gpow2p128_x, gpow2p128_y, B8X, B8Y
} from "@solidity/fields/SCL_babyjujub.sol";
import {ecGenMulmuladdB4W, ecGenMulmuladdB4W_core} from "@solidity/elliptic/SCL_mulmuladdX_fullgenW.sol";
import {ecGenMulmuladdX_store_core} from "@solidity/elliptic/SCL_mulmuladdX_fullgen_b4.sol";

/// external wrapper: gas measurement and memory isolation, as a calling contract would do
contract BJJWrap {
    function verifyRaw(uint256 hm, uint256 r8x, uint256 r8y, uint256 s, uint256 ax, uint256 ay)
        external
        view
        returns (bool)
    {
        return BJJ.verifyRaw(hm, r8x, r8y, s, ax, ay);
    }

    function verifyRawW(uint256 hm, uint256 r8x, uint256 r8y, uint256 s, uint256 wx, uint256 wy)
        external
        view
        returns (bool)
    {
        return BJJ.verifyRawW(hm, r8x, r8y, s, wx, wy);
    }

    function verifyRawB4(uint256 hm, uint256 r8x, uint256 r8y, uint256 s, uint256[4] memory w)
        external
        view
        returns (bool)
    {
        return BJJ.verifyRawB4(hm, r8x, r8y, s, w);
    }

    function pubKeyToW8(uint256 ax, uint256 ay) external view returns (uint256, uint256) {
        return BJJ.pubKeyToW8(ax, ay);
    }

    function pubKeyToW8B4(uint256 ax, uint256 ay) external view returns (uint256[4] memory) {
        return BJJ.pubKeyToW8B4(ax, ay);
    }

    function mma(uint256 qx, uint256 qy, uint256 u, uint256 v) external view returns (uint256, uint256) {
        return BJJ.ecMulmuladd(qx, qy, u, v);
    }
}

struct Vec {
    uint256[] hm;
    uint256[] r8x;
    uint256[] r8y;
    uint256[] s;
    uint256[] ax;
    uint256[] ay;
    uint256[] ok;
    string[] tag;
}

contract SCL_BabyJubJub_Test is Test {
    BJJWrap w;
    string eddsa;
    string vec;

    function setUp() public {
        w = new BJJWrap();
        eddsa = vm.readFile("test/vectors/eddsa.json");
        vec = vm.readFile("test/vectors/bjj.json");
    }

    function arr(string memory d, string memory k) internal pure returns (uint256[] memory) {
        return vm.parseJsonUintArray(d, k);
    }

    /// Base8 is mapped to the generator, 2^128.G matches the field file, n.G = O
    function test_isomorphism() public view {
        (uint256 X, uint256 Y) = BJJ.ed2W(B8X, B8Y);
        assertEq(X, gx);
        assertEq(Y, gy);
        assertTrue(BJJ.ecAff_isOnCurve(X, Y));
        assertTrue(BJJ.ed_isOnCurve(B8X, B8Y));
        (uint256 x, uint256 y) = BJJ.W2ed(X, Y);
        assertEq(x, B8X);
        assertEq(y, B8Y);
        (X, Y) = ecGenMulmuladdB4W([uint256(0), 0, p, a, gx, gy], 1 << 128, 0);
        assertEq(X, gpow2p128_x);
        assertEq(Y, gpow2p128_y);
        (X, Y) = w.mma(0, 0, n, 0);
        assertEq(X, 0);
        assertEq(Y, 0);
        (X, Y) = w.mma(gx, gy, n - 1, 1);
        assertEq(X, 0);
        assertEq(Y, 0);
    }

    /// pubKeyToW8 and pubKeyToW8B4 == phi(8A), phi(2^128.8A) computed in python
    function test_pubKeyToW8() public view {
        uint256[] memory ax = arr(vec, ".w8.ax");
        uint256[] memory ay = arr(vec, ".w8.ay");
        uint256[] memory wx = arr(vec, ".w8.wx");
        uint256[] memory wy = arr(vec, ".w8.wy");
        uint256[] memory w128x = arr(vec, ".w8.w128x");
        uint256[] memory w128y = arr(vec, ".w8.w128y");
        for (uint256 i = 0; i < ax.length; i++) {
            (uint256 X, uint256 Y) = w.pubKeyToW8(ax[i], ay[i]);
            assertEq(X, wx[i]);
            assertEq(Y, wy[i]);
            uint256[4] memory W = w.pubKeyToW8B4(ax[i], ay[i]);
            assertEq(W[0], wx[i]);
            assertEq(W[1], wy[i]);
            assertEq(W[2], w128x[i]);
            assertEq(W[3], w128y[i]);
        }
        console2.log("keys:", ax.length);
    }

    function load(string memory d, string memory k) internal pure returns (Vec memory V) {
        V.hm = arr(d, string.concat(k, "hm"));
        V.r8x = arr(d, string.concat(k, "r8x"));
        V.r8y = arr(d, string.concat(k, "r8y"));
        V.s = arr(d, string.concat(k, "s"));
        V.ax = arr(d, string.concat(k, "ax"));
        V.ay = arr(d, string.concat(k, "ay"));
        V.ok = arr(d, string.concat(k, "ok"));
        V.tag = vm.parseJsonStringArray(d, string.concat(k, "tag"));
    }

    function load() internal view returns (Vec memory) {
        return load(eddsa, ".");
    }

    function check(Vec memory V, uint256 i) internal view {
        bool expected = V.ok[i] == 1;
        assertEq(w.verifyRaw(V.hm[i], V.r8x[i], V.r8y[i], V.s[i], V.ax[i], V.ay[i]), expected, V.tag[i]);
        if (BJJ.ed_isOnCurve(V.ax[i], V.ay[i])) {
            (uint256 wx, uint256 wy) = w.pubKeyToW8(V.ax[i], V.ay[i]);
            assertEq(w.verifyRawW(V.hm[i], V.r8x[i], V.r8y[i], V.s[i], wx, wy), expected, V.tag[i]);
            uint256[4] memory W = w.pubKeyToW8B4(V.ax[i], V.ay[i]);
            assertEq(w.verifyRawB4(V.hm[i], V.r8x[i], V.r8y[i], V.s[i], W), expected, V.tag[i]);
        }
    }

    /// circomlibjs signatures (Poseidon, MiMC7, MiMCSponge, Pedersen), altered, invalid and small order cases
    function test_circomlib_vectors() public view {
        Vec memory V = load();
        uint256 valid;
        for (uint256 i = 0; i < V.hm.length; i++) {
            check(V, i);
            if (V.ok[i] == 1) valid++;
        }
        console2.log("circomlib vectors:", V.hm.length, "valid:", valid);
    }

    /// keys 8A = c.B8 with a degenerate table: small multiples (2-bit window) and the 15 weak keys of the 4-dim table
    function test_weak_keys() public view {
        Vec memory V = load(vec, ".weak.");
        uint256[2] memory degen; // tables found degenerate by the engines: 2-bit window, 4-dim
        for (uint256 i = 0; i < V.hm.length; i++) {
            check(V, i);
            uint256 v = addmod(n - V.hm[i] % n, 0, n);
            uint256[4] memory W = w.pubKeyToW8B4(V.ax[i], V.ay[i]);
            (, uint256 Y, uint256 ZZ,) = ecGenMulmuladdB4W_core([W[0], W[1], p, a, gx, gy], V.s[i], v);
            if ((Y | ZZ) == 0) degen[0]++;
            (, Y, ZZ,) = ecGenMulmuladdX_store_core(
                [W[0], W[1], W[2], W[3], p, a, gx, gy, gpow2p128_x, gpow2p128_y], V.s[i], v
            );
            if ((Y | ZZ) == 0) degen[1]++;
        }
        // 10 of the 14 small multiples are degenerate in the 2-bit window (+/-1 in both), 15 keys in the 4-dim table
        assertEq(degen[0], 2 * 10 + 2 * 2);
        assertEq(degen[1], 2 * 15 + 2 * 2);
        console2.log("weak key signatures:", V.hm.length);
    }

    /// R8 = (0,1) with S != 0: the 4-dim engine reaches the point at infinity with Y != 0 (no fallback)
    function test_R8_neutral() public view {
        uint256[3] memory ks = [uint256(5), n - 7, 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcd];
        for (uint256 i = 0; i < 3; i++) {
            uint256[2] memory A;
            (A[0], A[1]) = w.mma(0, 0, ks[i], 0);
            (A[0], A[1]) = BJJ.W2ed(A[0], A[1]);
            uint256[4] memory W = w.pubKeyToW8B4(A[0], A[1]);
            uint256 hm = uint256(keccak256(abi.encode(i))) >> 2;
            uint256 S = mulmod(mulmod(8, ks[i], n), hm, n); // S.B8 = 8.hm.A, R8 = O
            (, uint256 Y, uint256 ZZ,) = ecGenMulmuladdX_store_core(
                [W[0], W[1], W[2], W[3], p, a, gx, gy, gpow2p128_x, gpow2p128_y], S, addmod(n - hm % n, 0, n)
            );
            assertEq(ZZ, 0);
            assertTrue(Y != 0);
            assertTrue(w.verifyRaw(hm, 0, 1, S, A[0], A[1]));
            assertTrue(w.verifyRawW(hm, 0, 1, S, W[0], W[1]));
            assertTrue(w.verifyRawB4(hm, 0, 1, S, W));
            assertFalse(w.verifyRawB4(hm, 0, 1, S + 1, W));
            assertFalse(w.verifyRawB4(hm, 0, p - 1, S, W));
        }
    }

    /// W8 off the curve and inconsistent precomputation are rejected
    function test_bad_keys() public view {
        Vec memory V = load();
        (uint256 wx, uint256 wy) = w.pubKeyToW8(V.ax[0], V.ay[0]);
        assertTrue(w.verifyRawW(V.hm[0], V.r8x[0], V.r8y[0], V.s[0], wx, wy));
        assertFalse(w.verifyRawW(V.hm[0], V.r8x[0], V.r8y[0], V.s[0], wx, wy + 1));
        assertFalse(w.verifyRawW(V.hm[0], V.r8x[0], V.r8y[0], V.s[0], wx + p, wy));
        uint256[4] memory W = w.pubKeyToW8B4(V.ax[0], V.ay[0]);
        assertTrue(w.verifyRawB4(V.hm[0], V.r8x[0], V.r8y[0], V.s[0], W));
        W[1] = p - W[1];
        assertFalse(w.verifyRawB4(V.hm[0], V.r8x[0], V.r8y[0], V.s[0], W));
        W[1] = p - W[1];
        W[3] = p - W[3];
        assertFalse(w.verifyRawB4(V.hm[0], V.r8x[0], V.r8y[0], V.s[0], W));
    }

    /// average gas over the valid Poseidon signatures
    function test_gas() public view {
        Vec memory V = load();
        uint256[5] memory acc;
        uint256 cnt;
        for (uint256 i = 0; i < V.hm.length; i++) {
            if (keccak256(bytes(V.tag[i])) != keccak256("poseidon")) continue;
            (uint256 wx, uint256 wy) = w.pubKeyToW8(V.ax[i], V.ay[i]);
            uint256[4] memory W = w.pubKeyToW8B4(V.ax[i], V.ay[i]);
            uint256 g = gasleft();
            assertTrue(w.verifyRaw(V.hm[i], V.r8x[i], V.r8y[i], V.s[i], V.ax[i], V.ay[i]));
            acc[0] += g - gasleft();
            g = gasleft();
            assertTrue(w.verifyRawW(V.hm[i], V.r8x[i], V.r8y[i], V.s[i], wx, wy));
            acc[1] += g - gasleft();
            g = gasleft();
            assertTrue(w.verifyRawB4(V.hm[i], V.r8x[i], V.r8y[i], V.s[i], W));
            acc[2] += g - gasleft();
            g = gasleft();
            w.pubKeyToW8(V.ax[i], V.ay[i]);
            acc[3] += g - gasleft();
            g = gasleft();
            w.pubKeyToW8B4(V.ax[i], V.ay[i]);
            acc[4] += g - gasleft();
            cnt++;
        }
        console2.log("verifyRaw   (Edwards key)          :", acc[0] / cnt);
        console2.log("verifyRawW  (precomputed W8)        :", acc[1] / cnt);
        console2.log("verifyRawB4 (precomputed W8, 2^128) :", acc[2] / cnt);
        console2.log("pubKeyToW8                          :", acc[3] / cnt);
        console2.log("pubKeyToW8B4                        :", acc[4] / cnt);
    }

    /// random consistency: R8 = S.B8 - 8hm.A must verify with the three key formats, hm+1 must not
    function testFuzz_consistency(uint256 k, uint256 s, uint256 hm) public view {
        k = bound(k, 1, n - 1);
        s = bound(s, 0, n - 1);
        hm = bound(hm, 0, type(uint256).max - 1);
        uint256[2] memory A;
        uint256[2] memory R;
        // A = k.B8 (Edwards)
        (A[0], A[1]) = w.mma(0, 0, k, 0);
        (A[0], A[1]) = BJJ.W2ed(A[0], A[1]);
        uint256[4] memory W = w.pubKeyToW8B4(A[0], A[1]);
        // R8 = s.B8 - hm.W8 computed by the engine, mapped back to Edwards
        (R[0], R[1]) = w.mma(W[0], W[1], s, addmod(n - hm % n, 0, n));
        (R[0], R[1]) = BJJ.W2ed(R[0], R[1]);
        assertTrue(w.verifyRaw(hm, R[0], R[1], s, A[0], A[1]));
        assertTrue(w.verifyRawW(hm, R[0], R[1], s, W[0], W[1]));
        assertTrue(w.verifyRawB4(hm, R[0], R[1], s, W));
        assertFalse(w.verifyRaw(hm + 1, R[0], R[1], s, A[0], A[1]));
        assertFalse(w.verifyRawB4(hm + 1, R[0], R[1], s, W));
    }
}
