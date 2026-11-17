# Architecture decisions

## ADR-1: affine window tables built with one inversion (2026-11-17)

Context: both RIP7696 engines kept their 15-point tables in XYZZ coordinates, so every addition of the main
loop was a full XYZZ addition with ZZ2 and ZZZ2 read from memory.

Decision: compute the Q-dependent points (and 2G, 3G for the first opcode, since the curve is a runtime input)
in XYZZ, then normalize them together with Montgomery's batch inversion: one modexp per call. Entries are
stored as [-x, y, -y, x] at T + 128k, with T the free memory pointer.

Consequences: mixed additions (11 mulmod) in the loops. The extra modexp costs 1.4K under Prague and 4K under
Osaka, far below the saving.

## ADR-2: halved doubling and signed accumulator, generic and a = -3 loops (2026-11-17)

Decision: doubling with U = Y, output scaled by 1/2, so M/2 = (3/2)X^2 + (a/2)ZZ^2 with both constants kept at
0x00 and 0x20. A second copy of each loop uses M/2 = (3/2)(X-ZZ)(X+ZZ) when a = p - 3. The accumulator holds
-A so that the addition needs no `sub`; in the 2-bit window its sign alternates every 2 bits, the first half of
a 4-bit group adds -T[d] (offset 0x40), the second T[d] (offset 0x20).

Consequences: the a = -3 loop only saves about 2K gas (one mulmod less, one addmod more) for 1.5 kB of code.

## ADR-3: weak keys return the point at infinity (2026-11-17)

Context: the API of the first opcode carries no group order, so a degenerate table (Q = +/-c.G for small c)
cannot be rewritten as (u + c.v)G as in FCL.

Decision: a degenerate table is detected by a zero product in the batch inversion and the result is the point at
infinity. The private key of such a Q is known, and SCL_ECCUTILS.SetKey already rejects all of them.

## ADR-4: free memory pointer left untouched (2026-11-17)

Context: the previous engines moved the free memory pointer to mload(0x40)+0x800 on entry and to the constant
0x880 on exit, which moves it backwards when the caller had allocated past 0x880.

Decision: tables and scratch live above the free memory pointer, which is never written; 0x00-0x3f holds the
halving constants. Loop state that does not fit in 16 stack slots (a = -3 flag, p, pending low word) sits in the
unused entry 0 of the table.

## ADR-5: SHA-512 in assembly (2026-11-17)

Context: Sha2Ext.sha512 cost 243K gas per block, half of an ed25519 verification.

Decision: state a..h on the stack, 8 rounds unrolled per iteration so that no variable is moved, K[t]+W[t]
computed in the schedule loop, rotations done with one shift on the 128-bit word x | x<<64, a single 64-bit mask
per sum (the bits left above bit 63 are multiples of 2^64). Sha2Ext is kept unchanged in external/.

## ADR-6: ed25519 verification without going back to affine Weierstrass (2026-11-17)

Decision: Verify and Verify_LE call ecGenMulmuladdB4W_core and map (X, Y, ZZ, ZZZ) to Edwards with
N = 3X - A.ZZ: ex = c.N.ZZZ/(3Y.ZZ), ey = (N - 3ZZ)/(N + 3ZZ), with one inversion of 3Y.ZZ.(N + 3ZZ).
WeierStrass2Edwards and edCompress stay available unchanged.

## ADR-7: audit scope (2026-11-17)

The rewritten engines, SHA-512, ed25519 mapping and the BabyJubJub library (0.2.0) are outside the
CryptoExperts and Veridise audits and the Formal Land proofs (ecAddn2, ecDblNeg, scalar extraction of the
previous b4 engine). The previous engines are kept in test/ref and every result is checked against them and
against a python oracle.

## ADR-8: BabyJubJub on the SCL Weierstrass engines (2026-11-17)

Context: circomlib EdDSA is verified as S.B8 == R8 + 8.hm.A on a twisted Edwards curve. FCL has both a
Weierstrass a = -3 version and a dedicated Edwards a = -1 version (118K against 133K under Prague).

Decision: SCL uses the same a = -3 model as FCL (same generator and constants), so the generic engines and their
a = -3 loops are reused unchanged; no Edwards engine is added. The verification computes S.G - hm.W8 with
W8 = phi(8A) and compares the XYZZ result with R8 mapped projectively, without inversion. Three key formats:
A (8A and phi recomputed, 3 doublings and one inversion), W8, and [W8, 2^128.W8] for the 4-dim engine.

Consequences: verifyRawB4 (115K Prague) is below the FCL Edwards version (118K) with a 47K one-time
precomputation per key; verifyRawW (149K) pays the generic engine (p and a read from memory, full reduction)
against FCL's specialized one (129K).

## ADR-9: weak keys in the BabyJubJub library (2026-11-17)

Context: ADR-3 makes degenerate tables return the point at infinity, which suits ECDSA (the key is rejected) but
not circomlib compatibility, where 8A = c.B8 for any c is a valid key that a signer can produce.

Decision: the library knows n, so keys W8 = +/-c.G, c in {1, 2, 3, 1/2, 3/2, 1/3, 2/3}, are rewritten as
(u + c.v).G before the 2-bit window, as in FCL. ecGenMulmuladdX_store_core returns (0,0,0,0) for a degenerate
table (15 keys, found by test/gen/bjj_vec.py) and for u = v = 0; a genuine point at infinity has Y != 0 since the
group has odd order. verifyRawB4 then falls back to verifyRawW, as for small order keys (W8 = (0,0)).

Consequences: the three entry points give the circomlib verdict for every key; the fallback costs one more
multiplication only for keys whose discrete logarithm relative to Base8 is known.
