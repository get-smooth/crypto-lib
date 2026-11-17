// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

// Yul SHA-512 against python hashlib and against Sha2Ext, gas on one and two blocks.

import "forge-std/Test.sol";
import {SCL_sha512} from "@solidity/hash/SCL_sha512.sol";
import {Sha2Ext} from "../external/sha512/Sha2Ext.sol";

contract ShaW {
    function opt(bytes memory m) external pure returns (bytes32, bytes32) {
        return SCL_sha512.sha512(m);
    }

    function ext(bytes memory m) external pure returns (bytes32, bytes32) {
        return Sha2Ext.sha512(m);
    }
}

contract SCL_sha512_opt_Test is Test {
    function test_sha512_vectors() public {
        ShaW w = new ShaW();
        string memory d = vm.readFile("test/vectors/sha512.json");
        bytes[] memory m = vm.parseJsonBytesArray(d, ".msg");
        bytes32[] memory hi = vm.parseJsonBytes32Array(d, ".hi");
        bytes32[] memory lo = vm.parseJsonBytes32Array(d, ".lo");
        for (uint256 i = 0; i < m.length; i++) {
            (bytes32 a, bytes32 b) = w.opt(m[i]);
            assertEq(a, hi[i], vm.toString(m[i].length));
            assertEq(b, lo[i], vm.toString(m[i].length));
            (a, b) = w.ext(m[i]);
            assertEq(a, hi[i]);
            assertEq(b, lo[i]);
        }
    }

    function testFuzz_sha512(bytes memory m) public {
        ShaW w = new ShaW();
        (bytes32 a, bytes32 b) = w.opt(m);
        (bytes32 c, bytes32 d) = w.ext(m);
        assertEq(a, c);
        assertEq(b, d);
    }

    function test_sha512_gas() public {
        ShaW w = new ShaW();
        bytes memory m1 = new bytes(65); // R || A || 1 byte, one block
        bytes memory m2 = new bytes(200); // two blocks
        uint256 g = gasleft();
        w.ext(m1);
        uint256 e1 = g - gasleft();
        g = gasleft();
        w.opt(m1);
        uint256 o1 = g - gasleft();
        g = gasleft();
        w.ext(m2);
        uint256 e2 = g - gasleft();
        g = gasleft();
        w.opt(m2);
        uint256 o2 = g - gasleft();
        console2.log("sha512 1 block  Sha2Ext / Yul:", e1, o1);
        console2.log("sha512 2 blocks Sha2Ext / Yul:", e2, o2);
    }
}
