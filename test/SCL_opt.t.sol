// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

// Optimized SCL engines: python oracle (test/gen) on P-256, secp256k1, Wei25519 and BabyJubJub (a = -3 model),
// differential against the previous version (test/ref),
// ECDSA P-256 (RIP7212, 4-dim B4), ed25519 (EIP6565, RFC 8032 vectors), gas.

import "forge-std/Test.sol";

import {ecGenMulmuladdB4W} from "@solidity/elliptic/SCL_mulmuladdX_fullgenW.sol";
import {ecGenMulmuladdX_store} from "@solidity/elliptic/SCL_mulmuladdX_fullgen_b4.sol";
import {SCL_RIP7212} from "@solidity/lib/libSCL_RIP7212.sol";
import {SCL_ECDSAB4} from "@solidity/lib/libSCL_ecdsab4.sol";
import {SCL_EIP6565} from "@solidity/lib/libSCL_EIP6565.sol";
import {SCL_EIP6565_UTILS} from "@solidity/lib/libSCL_eddsaUtils.sol";

import {ecGenMulmuladdB4W_ref} from "./ref/SCL_mulmuladdX_fullgenW_ref.sol";
import {ecGenMulmuladdX_store_ref} from "./ref/SCL_mulmuladdX_fullgen_b4_ref.sol";
import {SCL_RIP7212_REF} from "./ref/libSCL_RIP7212_ref.sol";
import {SCL_ECDSAB4_REF} from "./ref/libSCL_ecdsab4_ref.sol";
import {SCL_EIP6565_REF} from "./ref/libSCL_EIP6565_ref.sol";

contract SclRefW {
    function b4w(uint256[6] memory Q, uint256 u, uint256 v) external view returns (uint256, uint256) {
        return ecGenMulmuladdB4W_ref(Q, u, v);
    }

    function xstore(uint256[10] memory Q, uint256 u, uint256 v) external view returns (uint256) {
        return ecGenMulmuladdX_store_ref(Q, u, v);
    }

    function rip7212(bytes32 h, uint256 r, uint256 s, uint256 qx, uint256 qy) external view returns (bool) {
        return SCL_RIP7212_REF.verify(h, r, s, qx, qy);
    }

    function ecdsab4(bytes32 h, uint256 r, uint256 s, uint256[10] memory Q, uint256 n) external view returns (bool) {
        return SCL_ECDSAB4_REF.verify(h, r, s, Q, n);
    }

    function ed25519(string memory m, uint256 r, uint256 s, uint256[5] memory k) external view returns (bool) {
        return SCL_EIP6565_REF.Verify_LE(m, r, s, k);
    }
}

contract SclOptW {
    function b4w(uint256[6] memory Q, uint256 u, uint256 v) external view returns (uint256, uint256) {
        return ecGenMulmuladdB4W(Q, u, v);
    }

    function xstore(uint256[10] memory Q, uint256 u, uint256 v) external view returns (uint256) {
        return ecGenMulmuladdX_store(Q, u, v);
    }

    function rip7212(bytes32 h, uint256 r, uint256 s, uint256 qx, uint256 qy) external view returns (bool) {
        return SCL_RIP7212.verify(h, r, s, qx, qy);
    }

    function ecdsab4(bytes32 h, uint256 r, uint256 s, uint256[10] memory Q, uint256 n) external view returns (bool) {
        return SCL_ECDSAB4.verify(h, r, s, Q, n);
    }

    function ed25519(string memory m, uint256 r, uint256 s, uint256[5] memory k) external view returns (bool) {
        return SCL_EIP6565.Verify_LE(m, r, s, k);
    }
}

struct Cv {
    uint256[] qx;
    uint256[] qy;
    uint256[] q128x;
    uint256[] q128y;
    uint256[] u;
    uint256[] v;
    uint256[] x;
    uint256[] y;
    uint256[] c; // p, a, b, gx, gy, g128x, g128y, n
}

contract SCL_opt_Test is Test {
    SclRefW ref;
    SclOptW opt;
    string vec;

    function setUp() public {
        ref = new SclRefW();
        opt = new SclOptW();
        vec = vm.readFile("test/vectors/scl.json");
    }

    function load(string memory name) internal view returns (Cv memory C) {
        string memory k = string.concat(".", name, ".");
        C.qx = vm.parseJsonUintArray(vec, string.concat(k, "qx"));
        C.qy = vm.parseJsonUintArray(vec, string.concat(k, "qy"));
        C.q128x = vm.parseJsonUintArray(vec, string.concat(k, "q128x"));
        C.q128y = vm.parseJsonUintArray(vec, string.concat(k, "q128y"));
        C.u = vm.parseJsonUintArray(vec, string.concat(k, "u"));
        C.v = vm.parseJsonUintArray(vec, string.concat(k, "v"));
        C.x = vm.parseJsonUintArray(vec, string.concat(k, "x"));
        C.y = vm.parseJsonUintArray(vec, string.concat(k, "y"));
        C.c = vm.parseJsonUintArray(vec, string.concat(k, "curve"));
    }

    function q6(Cv memory C, uint256 i) internal pure returns (uint256[6] memory) {
        return [C.qx[i], C.qy[i], C.c[0], C.c[1], C.c[3], C.c[4]];
    }

    function q10(Cv memory C, uint256 i) internal pure returns (uint256[10] memory) {
        return [C.qx[i], C.qy[i], C.q128x[i], C.q128y[i], C.c[0], C.c[1], C.c[3], C.c[4], C.c[5], C.c[6]];
    }

    /// both engines against the python oracle, on the three curves
    function check_curve(string memory name) internal view {
        Cv memory C = load(name);
        uint256[4] memory bad; // ref b4w, ref xstore
        uint256[4] memory gas; // ref/opt b4w, ref/opt xstore (16 random cases)
        for (uint256 i = 0; i < C.u.length; i++) {
            (uint256 X, uint256 Y) = opt.b4w(q6(C, i), C.u[i], C.v[i]);
            assertEq(X, C.x[i], string.concat(name, " b4w x ", vm.toString(i)));
            assertEq(Y, C.y[i], string.concat(name, " b4w y ", vm.toString(i)));
            assertEq(opt.xstore(q10(C, i), C.u[i], C.v[i]), C.x[i], string.concat(name, " xstore ", vm.toString(i)));
            (X, Y) = ref.b4w(q6(C, i), C.u[i], C.v[i]);
            if (X != C.x[i] || Y != C.y[i]) bad[0]++;
            if (ref.xstore(q10(C, i), C.u[i], C.v[i]) != C.x[i]) bad[1]++;
            if (i < 16) {
                uint256 g = gasleft();
                ref.b4w(q6(C, i), C.u[i], C.v[i]);
                gas[0] += g - gasleft();
                g = gasleft();
                opt.b4w(q6(C, i), C.u[i], C.v[i]);
                gas[1] += g - gasleft();
                g = gasleft();
                ref.xstore(q10(C, i), C.u[i], C.v[i]);
                gas[2] += g - gasleft();
                g = gasleft();
                opt.xstore(q10(C, i), C.u[i], C.v[i]);
                gas[3] += g - gasleft();
            }
        }
        console2.log(name, "cases:", C.u.length);
        console2.log("  wrong in the previous version, b4w / xstore:", bad[0], bad[1]);
        console2.log("  ecGenMulmuladdB4W     ref / opt:", gas[0] / 16, gas[1] / 16);
        console2.log("  ecGenMulmuladdX_store ref / opt:", gas[2] / 16, gas[3] / 16);
    }

    function test_p256() public view {
        check_curve("p256");
    }

    function test_secp256k1() public view {
        check_curve("k1");
    }

    function test_wei25519() public view {
        check_curve("wei25519");
    }

    function test_babyjujub() public view {
        check_curve("bjj");
    }

    /// ECDSA P-256: RIP7212 and 4-dim B4 verifiers, random valid and altered signatures
    function test_ecdsa() public view {
        string memory k = ".ecdsa.";
        uint256[] memory h = vm.parseJsonUintArray(vec, string.concat(k, "h"));
        uint256[] memory r = vm.parseJsonUintArray(vec, string.concat(k, "r"));
        uint256[] memory s = vm.parseJsonUintArray(vec, string.concat(k, "s"));
        uint256[] memory qx = vm.parseJsonUintArray(vec, string.concat(k, "qx"));
        uint256[] memory qy = vm.parseJsonUintArray(vec, string.concat(k, "qy"));
        uint256[] memory q128x = vm.parseJsonUintArray(vec, string.concat(k, "q128x"));
        uint256[] memory q128y = vm.parseJsonUintArray(vec, string.concat(k, "q128y"));
        uint256[] memory ok = vm.parseJsonUintArray(vec, string.concat(k, "ok"));
        uint256[] memory c = vm.parseJsonUintArray(vec, ".p256.curve");
        uint256[4] memory gas;
        for (uint256 i = 0; i < h.length; i++) {
            uint256[10] memory Q = [qx[i], qy[i], q128x[i], q128y[i], c[0], c[1], c[3], c[4], c[5], c[6]];
            uint256 g = gasleft();
            assertEq(ref.rip7212(bytes32(h[i]), r[i], s[i], qx[i], qy[i]), ok[i] == 1);
            gas[0] += g - gasleft();
            g = gasleft();
            assertEq(opt.rip7212(bytes32(h[i]), r[i], s[i], qx[i], qy[i]), ok[i] == 1);
            gas[1] += g - gasleft();
            g = gasleft();
            assertEq(ref.ecdsab4(bytes32(h[i]), r[i], s[i], Q, c[7]), ok[i] == 1);
            gas[2] += g - gasleft();
            g = gasleft();
            assertEq(opt.ecdsab4(bytes32(h[i]), r[i], s[i], Q, c[7]), ok[i] == 1);
            gas[3] += g - gasleft();
        }
        console2.log("SCL_RIP7212.verify ref / opt:", gas[0] / h.length, gas[1] / h.length);
        console2.log("SCL_ECDSAB4.verify ref / opt:", gas[2] / h.length, gas[3] / h.length);
    }

    /// ed25519 RFC 8032 vectors (first 64 lines of ed25519tv.json), Verify_LE, with an altered s
    function test_ed25519() public {
        string memory file = "./test/utils/ed25519tv.json";
        uint256[2] memory gas;
        uint256 cnt;
        for (uint256 i = 0; i < 64; i++) {
            string memory line = vm.readLine(file);
            if (bytes(line).length == 0) break;
            uint256 secret = uint256(stdJson.readBytes32(line, ".secret"));
            uint256 r = uint256(stdJson.readBytes32(line, ".r"));
            uint256 s = uint256(stdJson.readBytes32(line, ".s"));
            bytes memory m = stdJson.readBytes(line, ".msg");
            (uint256[5] memory ext,) = SCL_EIP6565_UTILS.SetKey(secret);
            uint256 g = gasleft();
            assertTrue(ref.ed25519(string(m), r, s, ext));
            gas[0] += g - gasleft();
            g = gasleft();
            assertTrue(opt.ed25519(string(m), r, s, ext));
            gas[1] += g - gasleft();
            assertFalse(opt.ed25519(string(m), r, s ^ (1 << 8), ext));
            cnt++;
        }
        vm.closeFile(file);
        console2.log("SCL_EIP6565.Verify_LE ref / opt:", gas[0] / cnt, gas[1] / cnt);
    }

    /// weak keys whose 2-bit window table is degenerate (here Q = -G) give the point at infinity, so ECDSA fails;
    /// SCL_ECCUTILS.SetKey already rejects them. Q = 2G is not degenerate for this table and stays exact.
    function test_weakkey() public view {
        Cv memory C = load("p256");
        uint256[6] memory Q = [C.c[3], C.c[0] - C.c[4], C.c[0], C.c[1], C.c[3], C.c[4]];
        (uint256 X, uint256 Y) = opt.b4w(Q, 12345, 678);
        assertEq(X, 0);
        assertEq(Y, 0);
        assertFalse(opt.rip7212(bytes32(uint256(1)), 1, 1, Q[0], Q[1]));
    }
}
