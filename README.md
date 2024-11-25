# SmoothCryptoLib (SCL)
A Cryptographic Library for Smooth Blockchain uses.


# Source 


## Solidity (onchain Contracts)

On chain contracts are available [here](./src/README.md).

## Javascript (front code)

Source code for front is available [here](./src/libMPC/README.md).



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

We are also grateful to Guido (https://github.com/guidovranken) which notice by its independant (and amazing) Fuzzing work that our weak keys testing was incorrect.

## Javascript

Code hasn't been audited and is delivered for experiments purposes only. Do not use in production.

# Acknowledments

The following work has been half-funded by the Ethereum Fundation grant number FY24-1386:
 * ed25519 solidity (libSCL_RIP6565.sol )
 * Formal Verification is hosted on [Formal Land](https://github.com/formal-land/coq-of-solidity/tree/guillaume-claret%40experiments-verification-mulmuladdX_fullgen_b4/coq/CoqOfSolidity/contracts/scl/mulmuladdX_fullgen_b4) repo. 
 * libMPC
   - SCL_Musig2.mjs 

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
