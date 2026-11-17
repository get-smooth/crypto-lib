# SmoothCryptoLib (SCL)
A Cryptographic Library for Smooth Blockchain uses.


## Compilation

Clone the repository, then type `forge test`. (Some troubles are solved running `foundryup` and `forge init --force`)

## Deployment

Run deploy.sh to deploy the code on a target chain. 
The values `$RPC` and `$CHAINID` shall be set to the chain ones. 
The toy private and public key shall be replaced and funded (current can be used for testnet). 



## Benchmarks


### Forge results

The benchmarks average external calls over random inputs (test/SCL_opt.t.sol, test/SCL_sha512_opt.t.sol), solc 0.8.30, optimizer 1000000 runs, without via-IR. Osaka prices the modexp precompile three times higher than Prague (EIP-7883), hence two columns. Previous version in brackets.

| curve | Function  | gas Osaka | gas Prague | Comment | File|
|--------:|---------|:--:|:--:|:----|:----|
| P256 | SCL_RIP7212.verify | 163K (211K) | 155K (205K) | ECDSA using RIP7696 (first opcode) | libSCL_RIP7212.sol |
| P256 | SCL_ECDSAB4.verify | 130K (165K) | 122K (160K) | ECDSA using RIP7696 (second opcode), precomputed 2^128.Q | libSCL_ecdsab4.sol |
| ed25519 | SCL_EIP6565.Verify_LE | 217K (515K) | 211K (506K) | RFC 8032, one block message | libSCL_EIP6565.sol |
| BabyJubJub | SCL_BABYJUJUB.verifyRawB4 | 118K | 115K | circomlib EdDSA from the hashed challenge, precomputed [W8, 2^128.W8] | libSCL_babyjujub.sol |
| BabyJubJub | SCL_BABYJUJUB.verifyRawW | 152K | 149K | same, precomputed W8 | libSCL_babyjujub.sol |
| BabyJubJub | SCL_BABYJUJUB.verifyRaw | 158K | 152K | same, circomlib public key A | libSCL_babyjujub.sol |
| BabyJubJub | pubKeyToW8 / pubKeyToW8B4 | 7K / 49K | 4K / 47K | key precomputation, once per key | libSCL_babyjujub.sol |
| P256, k1, Wei25519, BabyJubJub | ecGenMulmuladdB4W | 156K to 161K (202K to 206K) | 150K to 156K (199K to 203K) | uG+vQ, any short Weierstrass curve | SCL_mulmuladdX_fullgenW.sol |
| P256, k1, Wei25519, BabyJubJub | ecGenMulmuladdX_store | 122K to 124K (158K to 159K) | 117K to 119K (155K to 156K) | 4-dim uG+vQ | SCL_mulmuladdX_fullgen_b4.sol |
| | SCL_sha512.sha512 | 43K per block (243K, Sha2Ext) | same | | SCL_sha512.sol |

Weak keys whose window table is degenerate (Q = +/-c.G for c in {1, 2, 3, 1/2, 3/2, 1/3, 2/3} for the first opcode, the keys listed in SCL_ECCUTILS.SetKey for the second one) return the point at infinity, so that a verification fails; SetKey rejects all of them. The BabyJubJub library accepts them as circomlib does: small multiples of G are rewritten as (u + c.v).G and degenerate 4-dim tables fall back to the first opcode.

The BabyJubJub functions check S.B8 == R8 + 8.hm.A, hm being the challenge already hashed by the caller (Poseidon, MiMC7, MiMCSponge or Pedersen in circomlib), on the short Weierstrass curve with a = -3 isomorphic to the circomlib curve (src/fields/SCL_babyjujub.sol). The test vectors come from the circomlibjs signers (test/gen/gen_vectors.mjs).



### Onchain results


| PR # | Create2 | Mainnets | Testnets |
|--------:|---------|:--:|:----|
|[N/A](https://github.com/rdubois-crypto/FreshCryptoLib/pull/46)| 0x05eFAC4C53Ec12F11f144d0a0D18Df6dfDf83409    | |  [Sepolia](https://sepolia.etherscan.io/address/0x05eFAC4C53Ec12F11f144d0a0D18Df6dfDf83409#code) ,[Optimism](https://sepolia.etherscan.io/address/0x05eFAC4C53Ec12F11f144d0a0D18Df6dfDf83409#code) |  
||         |  |         |



# Audits 

The results of the completed audits are in the doc/audit folder.


| Team    | branch  | Target |status |Residual risks|
|--------:|---------|:---------|:---------|:--:|
| [CryptoExperts](https://github.com/get-smooth/crypto-lib/tree/main/doc/Audits) | CryptoExperts  |P256 | Completed | 0|
| [Veridise](https://github.com/get-smooth/crypto-lib/tree/main/doc/Audits) | Veridise  |P256, Ed25519 |  Completed | 0 |
| [Formal Land](https://github.com/formal-land/coq-of-solidity/tree/guillaume-claret%40experiments-verification-mulmuladdX_fullgen_b4/coq/CoqOfSolidity/contracts/scl/mulmuladdX_fullgen_b4)| Veridise  | RIP7696 |  Partial Proving | 0 |

CryptoExperts and Veridise audits consisted in human auditing of the code. Formal Land conducted a partial formal verification of the code. Due to its mathematical complexity, the perimeter was restricted to ecAddn2, ecDblNeg and scalar extraction.
See [here](https://github.com/formal-land/coq-of-solidity/tree/guillaume-claret%40experiments-verification-mulmuladdX_fullgen_b4/coq/CoqOfSolidity/contracts/scl/mulmuladdX_fullgen_b4) for the coq proof of the library.

We are also grateful to Guido (https://github.com/guidovranken) which notice by its independant (and amazing) Fuzzing work that our weak keys testing was incorrect.

# Curves implementation status



| curve | status  | branch | Comment | File| 
|--------:|---------|:--:|:----|:----|
| P256 | OK   | main  | ECDSA using RIP7696 (first opcode)  | libSCL_7212.sol |
| P256 | OK   | main  | ECDSA using RIP7696 (second opcode)  | libSCL_ECDSAb4.sol |
| Ed25519|     OK    | main | EDDSA using RIP7696 (first opcode) with isogenies |    libSCL_RIP6565.sol     ||
| BabyJubJub | OK | main | circomlib EdDSA from the hashed challenge, RIP7696 (both opcodes) with isomorphism | libSCL_babyjujub.sol |

# Acknowledments

The following work has been half-funded by the Ethereum Fundation grant number FY24-1386:
 * ed25519 solidity (libSCL_RIP6565.sol )

SCL is build by the same team of the previous FCL. As such all previous contributors are credited.

# Our work in Production

Prior to SCL implementation, our experimental library FCL is still in production in various environments:

* Base Smart Wallet: fast onboarding using FCL: https://www.smart-wallet.xyz/, deployed at 0x0BA5ED0c6AA8c49038F819E587E2633c4A9F428a (Base main and Sepolia)
* Cometh Connect: https://github.com/cometh-hq/p256-signer/blob/79d58bc619109a069e212d54a18744d3803731bc/contracts/P256Signer.sol
* Metamask Delegation Toolkit https://github.com/MetaMask/delegation-framework/blob/635f717372f58a2b338964ba8e3de4ad285c9a47/src/libraries/P256FCLVerifierLib.sol
* Safe : https://github.com/safe-global/safe-modules/tree/main/modules/passkey/contracts/vendor/FCL


## License 
License: This software is licensed under MIT License (see LICENSE FILE at root directory of project).
