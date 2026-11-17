# SmoothCryptoLib (SCL)
A Cryptographic Library for Smooth Blockchain uses.


# Source 


## Solidity (onchain Contracts)

On chain contracts are available [here](./src/README.md).

## Javascript (front code)

Source code for front is available [here](./src/libMPC/README.md).

## What can I do with SCL:

- Integrate Passkey on any chain using RIP7696/RIP7212 contracts.
- Delegate with 7702 to any curve instead of k1, using RIP7696. 
- Deploy a multisig account, where the governance is kept offchain using Musig2, either on curve k1 (compatibility with BIP327) or ed25519 (Cosmos/Solana).
- Verify circomlib EdDSA signatures on BabyJubJub (ERC-2494) from the hashed challenge (Poseidon, MiMC7, MiMCSponge or Pedersen), with the same acceptance as circomlibjs.

## Gas

Average of external calls, solc 0.8.30, 1000000 optimizer runs, without via-IR, under Prague (Osaka in brackets, EIP-7883 triples the price of the modexp precompile). Previous version of the engines in the last column. Detailed figures in [src/README.md](./src/README.md).

| curve | function | gas | before |
|:--|:--|--:|--:|
| P256 | SCL_RIP7212.verify | 155K (163K) | 205K |
| P256 | SCL_ECDSAB4.verify, precomputed 2^128.Q | 122K (130K) | 160K |
| ed25519 | SCL_EIP6565.Verify_LE, one block message | 211K (217K) | 506K |
| BabyJubJub | SCL_BABYJUJUB.verifyRawB4, precomputed [8A, 2^128.8A] | 115K (118K) | |
| BabyJubJub | SCL_BABYJUJUB.verifyRawW, precomputed 8A | 149K (152K) | |
| BabyJubJub | SCL_BABYJUJUB.verifyRaw, circomlib public key | 152K (158K) | |

The engines (src/elliptic) were rewritten in 0.1.0 with the same API: affine window tables built with one inversion, halved doubling, specialized loop for a = -3, SHA-512 in assembly. The changes are listed in [VERSION.md](./VERSION.md) and the design choices in [DECISIONS.md](./DECISIONS.md).

## Tests

```sh
git submodule update --init --recursive
forge test
forge test --evm-version prague -vv --match-contract "SCL_opt|SCL_BabyJubJub"
```

The results are checked against python oracles, the previous engines (test/ref), RFC 8032, Wycheproof and circomlibjs signers. The vector generators are in [test/gen](./test/gen/README.md) (python3, and node for circomlibjs).


# Audits 

## Solidity 
The results of the completed audits are in the doc/audit folder.


| Team    | branch  | Target |status |Residual risks|
|--------:|---------|:---------|:---------|:--:|
| [CryptoExperts](https://github.com/get-smooth/crypto-lib/tree/main/doc/Audits) | CryptoExperts  |P256 | Completed | 0|
| [Veridise](https://github.com/get-smooth/crypto-lib/tree/main/doc/Audits) | Veridise  |P256, Ed25519 |  Completed | 0 |
| [Formal Land](https://github.com/formal-land/coq-of-solidity/tree/guillaume-claret%40experiments-verification-mulmuladdX_fullgen_b4/coq/CoqOfSolidity/contracts/scl/mulmuladdX_fullgen_b4)| Veridise  | RIP7696 |  Partial Proving | 0 |

CryptoExperts and Veridise audits consisted in human auditing of the code. Formal Land conducted a partial formal verification of the code. Due to its mathematical complexity, the perimeter was restricted to ecAddn2, ecDblNeg and scalar extraction.
See [here](https://github.com/formal-land/coq-of-solidity/tree/guillaume-claret%40experiments-verification-mulmuladdX_fullgen_b4/coq/CoqOfSolidity/contracts/scl/mulmuladdX_fullgen_b4) for the coq proof of the library.

The gas optimized engines and SHA-512 of version 0.1.0 and the BabyJubJub library of version 0.2.0 (see [VERSION.md](./VERSION.md)) postdate these audits: SCL_mulmuladdX_fullgenW.sol, SCL_mulmuladdX_fullgen_b4.sol, SCL_sha512.sha512, SCL_EIP6565.ecMulmuladd_edCompress and libSCL_babyjujub.sol are not covered by them, nor by the Formal Land proofs. The previous engines are kept in test/ref for differential testing.

We are also grateful to Guido (https://github.com/guidovranken) which notice by its independant (and amazing) Fuzzing work that our weak keys testing was incorrect.

## Javascript

Code hasn't been audited and is delivered for experiments purposes only. Do not use in production.

# Acknowledments

The following work has been half-funded by the Ethereum Fundation grant number FY24-1386:
 * ed25519 solidity (libSCL_RIP6565.sol )
 * Formal Verification is hosted on [Formal Land](https://github.com/formal-land/coq-of-solidity/tree/guillaume-claret%40experiments-verification-mulmuladdX_fullgen_b4/coq/CoqOfSolidity/contracts/scl/mulmuladdX_fullgen_b4) repo. 
 * libMPC
   - SCL_Musig2.mjs over secp256K1 and ed25519.

SCL is build by the same team of the previous FCL. 

# Our work in Production

Prior to SCL implementation, our experimental library FCL is still in production in various environments:

* Base Smart Wallet: fast onboarding using FCL: https://www.smart-wallet.xyz/, deployed at 0x0BA5ED0c6AA8c49038F819E587E2633c4A9F428a (Base main and Sepolia)
* Cometh Connect: https://github.com/cometh-hq/p256-signer/blob/79d58bc619109a069e212d54a18744d3803731bc/contracts/P256Signer.sol
* Metamask Delegation Toolkit https://github.com/MetaMask/delegation-framework/blob/635f717372f58a2b338964ba8e3de4ad285c9a47/src/libraries/P256FCLVerifierLib.sol
* Safe : https://github.com/safe-global/safe-modules/tree/main/modules/passkey/contracts/vendor/FCL
* Unruggable Wallet : https://github.com/rdubois-crypto/UnruggableWallet/tree/main/src. A hackathon project using Musig2 as building block for a Wallet immune to hardware trapdoor. 


## License 
License: This software is licensed under MIT License (see LICENSE FILE at root directory of project).
