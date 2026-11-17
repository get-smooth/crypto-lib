# Generators

Run from the repository root.

```sh
python3 test/gen/build_engines.py src/elliptic/SCL_mulmuladdX_fullgenW.sol src/elliptic/SCL_mulmuladdX_fullgen_b4.sol
python3 test/gen/build_sha512.py src/hash/SCL_sha512.sol
python3 test/gen/build_babyjujub.py src/fields/SCL_babyjujub.sol
(cd test/gen && python3 scl_vec.py ../vectors/scl.json)
```

`(cd test/gen && python3 scl_vec.py ../vectors/scl.json bjj)` regenerates only the listed curves and keeps the rest
of the file.

BabyJubJub (circomlibjs signers, then key precomputation and weak keys):

```sh
(cd test/gen && npm install)
node test/gen/gen_vectors.mjs test/vectors/eddsa.json test/vectors/keys.json
(cd test/gen && python3 bjj_vec.py ../vectors/keys.json ../vectors/bjj.json)
```

`bjj.py` holds the curve maps (Edwards, Montgomery, Weierstrass a = -3); `bjj_vec.py` derives the keys whose
table is degenerate in each engine from the order of the additions of the generated code.

`scl_vec.py` writes random and edge cases for P-256, secp256k1, Wei25519 and BabyJubJub (random values from
`secrets`); `rare_cases.py` builds scalars that drive both loops through their rare paths (accumulator equal to
the table entry, to its opposite, at infinity). The SHA-512 vectors (test/vectors/sha512.json) are hashlib digests of random
messages of 26 lengths around the padding boundaries.
