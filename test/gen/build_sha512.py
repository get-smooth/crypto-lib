"""Generates the Yul SHA-512 of src/hash/SCL_sha512.sol (function sha512, same output as Sha2Ext.sha512).
State a..h on the stack, 8 rounds unrolled per iteration (no variable rotation), K[t]+W[t] computed once
per block in the schedule loop, all 64-bit additions masked once.
usage: python3 build_sha512.py <SCL_sha512.sol>"""
import sys

K = [0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538,
     0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242, 0x12835b0145706fbe,
     0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2, 0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,
     0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
     0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5, 0x983e5152ee66dfab,
     0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,
     0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed,
     0x53380d139d95b3df, 0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
     0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218,
     0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8, 0x19a4c116b8d2d0c8, 0x1e376c085141ab53,
     0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373,
     0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
     0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b, 0xca273eceea26619c,
     0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba, 0x0a637dc5a2c898a6,
     0x113f9804bef90dae, 0x1b710b35131c471b, 0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,
     0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817]
H0 = [0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
      0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179]

M = "0xffffffffffffffff"


def rot(x, n):
    return f"or(shr({n}, {x}), shl({64 - n}, {x}))"


def rnd(a, b, c, d, e, f, g, h, j):
    """one round, j = offset of K[t]+W[t] in words from kw: d += T1, h = T1 + T2.
    Rotations on the 128-bit duplicated word x | x<<64 are single shifts; the bits above 63 they leave
    are multiples of 2^64, so only the final sums are masked."""
    return f"""                    {{
                        let x := or({e}, shl(64, {e}))
                        {h} := add(add({h}, xor(xor(shr(14, x), shr(18, x)), shr(41, x))), add(xor({g}, and({e}, xor({f}, {g}))), mload(add(kw, {hex(32 * j)}))))
                        {d} := and(add({d}, {h}), {M})
                        x := or({a}, shl(64, {a}))
                        {h} := and(add({h}, add(xor(xor(shr(28, x), shr(34, x)), shr(39, x)), or(and({a}, {b}), and({c}, or({a}, {b}))))), {M})
                    }}"""


names = list("abcdefgh")
rounds = []
for j in range(8):
    r = names[-j:] + names[:-j] if j else names
    rounds.append(rnd(*r, j))
ROUNDS = "\n".join(rounds)
KSTORE = "\n".join(f"            mstore(add(KT, {hex(32 * t)}), {hex(k)})" for t, k in enumerate(K))

KSTORE = "\n".join(f"            mstore(add(high, {hex(32 * t)}), {hex(k)})" for t, k in enumerate(K))

SRC = f'''
    /**
     * @dev SHA-512 of a memory byte array, same output as Sha2Ext.sha512 (two big endian halves).
     *      Uses memory above the free memory pointer as scratch, the pointer is not moved.
     *      Layout from the free memory pointer: K, W, K+W (80 words each), saved state (8 words), padded message.
     */
    function sha512(bytes memory message) internal pure returns (bytes32 high, bytes32 low) {{
        assembly ("memory-safe") {{
            high := mload(0x40) // base of the scratch area
{KSTORE}
            {{
                let len := mload(message)
                let buf := add(high, 0x1f00)
                let n := shl(7, shr(7, add(len, 0x90))) // padded length, multiple of 128
                for {{ let i := 0 }} lt(i, n) {{ i := add(i, 0x20) }} {{ mstore(add(buf, i), 0) }}
                for {{ let i := 0 }} lt(i, len) {{ i := add(i, 0x20) }} {{ mstore(add(buf, i), mload(add(message, add(0x20, i)))) }}
                if and(len, 0x1f) {{
                    let pt := add(buf, and(len, not(0x1f)))
                    mstore(pt, and(mload(pt), not(shr(shl(3, and(len, 0x1f)), not(0)))))
                }}
                mstore8(add(buf, len), 0x80)
                let pt := add(buf, sub(n, 0x20))
                mstore(pt, or(and(mload(pt), not(0xffffffffffffffffffffffffffffffff)), shl(3, len)))
                message := buf // first block
                low := add(buf, n) // end of the padded message
            }}
            let a := {hex(H0[0])}
            let b := {hex(H0[1])}
            let c := {hex(H0[2])}
            let d := {hex(H0[3])}
            let e := {hex(H0[4])}
            let f := {hex(H0[5])}
            let g := {hex(H0[6])}
            let h := {hex(H0[7])}
            for {{}} lt(message, low) {{ message := add(message, 0x80) }} {{
                // message schedule: W[t] at high+0xa00, K[t]+W[t] at high+0x1400
                for {{ let t := 0 }} lt(t, 0x200) {{ t := add(t, 0x80) }} {{
                    let x := mload(add(message, shr(2, t)))
                    let o := add(add(high, 0xa00), t)
                    mstore(o, shr(192, x))
                    mstore(add(o, 0xa00), add(shr(192, x), mload(add(high, t))))
                    mstore(add(o, 0x20), and(shr(128, x), {M}))
                    mstore(add(o, 0xa20), add(and(shr(128, x), {M}), mload(add(high, add(t, 0x20)))))
                    mstore(add(o, 0x40), and(shr(64, x), {M}))
                    mstore(add(o, 0xa40), add(and(shr(64, x), {M}), mload(add(high, add(t, 0x40)))))
                    mstore(add(o, 0x60), and(x, {M}))
                    mstore(add(o, 0xa60), add(and(x, {M}), mload(add(high, add(t, 0x60)))))
                }}
                for {{ let t := add(high, 0xc00) }} lt(t, add(high, 0x1400)) {{ t := add(t, 0x20) }} {{
                    let w := mload(sub(t, 0x40))
                    let x := or(w, shl(64, w))
                    w := add(xor(xor(shr(19, x), shr(61, x)), shr(6, w)), mload(sub(t, 0xe0)))
                    x := mload(sub(t, 0x1e0))
                    w := add(w, add(xor(xor(shr(1, or(x, shl(64, x))), shr(8, or(x, shl(64, x)))), shr(7, x)), mload(sub(t, 0x200))))
                    w := and(w, {M})
                    mstore(t, w)
                    mstore(add(t, 0xa00), add(w, mload(sub(t, 0xa00))))
                }}
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
                for {{ let kw := add(high, 0x1400) }} lt(kw, add(high, 0x1e00)) {{ kw := add(kw, 0x100) }} {{
{ROUNDS}
                }}
                a := and(add(a, mload(add(high, 0x1e00))), {M})
                b := and(add(b, mload(add(high, 0x1e20))), {M})
                c := and(add(c, mload(add(high, 0x1e40))), {M})
                d := and(add(d, mload(add(high, 0x1e60))), {M})
                e := and(add(e, mload(add(high, 0x1e80))), {M})
                f := and(add(f, mload(add(high, 0x1ea0))), {M})
                g := and(add(g, mload(add(high, 0x1ec0))), {M})
                h := and(add(h, mload(add(high, 0x1ee0))), {M})
            }}
            high := or(or(shl(192, a), shl(128, b)), or(shl(64, c), d))
            low := or(or(shl(192, e), shl(128, f)), or(shl(64, g), h))
        }}
    }}
'''
src = open(sys.argv[1]).read()
marker = "    function Swap512("
start = src.find("\n    /**\n     * @dev SHA-512 of a memory byte array")
if start >= 0:
    end = src.index(marker)
    src = src[:start] + "\n" + src[end:]
src = src.replace(marker, SRC.lstrip("\n") + "\n" + marker, 1)
open(sys.argv[1], "w").write(src)
print("ok")
