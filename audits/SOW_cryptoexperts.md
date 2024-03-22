# Audit secp256r1
![alt text](image.png)

## Abstract

This document describes the input of the requested audit from Smoo.th to CryptoExperts of the SCL library P256 verifier. 

## Introduction

Smoo.th offers a unique UX, enabling onboard users to Web3 technologies, with a familiar experience, without even noticing the shift from classic web by leveraging the FIDO/passkeys framework. At the core of the product, the SCL library implements cryptographic primitives and protocols in solidity, targetting EVMs.

The library improves the previous most efficient implementation, while providing generic formulaes to implement other curves, such as ed25519 with the use of isogenies, or starkcurve.

 The  P256/secp256r1 is one of such primitive. The perimeter of the audit is restricted to the ECDSA verification function over P256 curve of the library. Used in conjonction with Account Abstraction, it allows to leverage the WebAuthn/Passkeys technology as a way to authenticate transactions on all EVM.


## Description

The SCL ECC implementation is build upon [RD23] paper. The high level function to be audited are:
 * libSCL_rip7212.sol : verify, performing a ECDSA verification as specified in [RIP7212] .
 * libSCL_ripB4.sol : implements the computation of $uP+vQ$, refered as ecmulmuladd, given the additional precomputed values $2^{128}.P, 2^{128}.Q$ as specified in [RIPB4].




## Algorithmic specification

ECDSA is a classic ECC primitive, securizing ETH transactions. One could report to [NIST-SP86] for exact specification. The main operation (in term of complexity of computations) of the verification is the computation of a value $uP+vQ$, where $u,v$ are scalars and $P,Q$ are points over the secp256r1 curve. The 2 implementations vary in this ecmulmuladd implementation:
* libSCL_rip7212.sol : implements the operation using the so called Shamir's trick with a 4-bit windowing. Reducing the number of operation to 15 ecADD+256 ecDBl + an average 60 ecAdd.
* libSCL_ripB4.sol : implements the operation using the trick with four points, reducing the number of operations to 15 ecADD+128 ecDBl + an average 120 ecAdd.


## Implementation notes

* most of the ecmulmuladd operator is written in assembly language, without having to use the via-IR flag. This constraints limit the stack size to 16, which restricts the number of intermediate variables. The high level of reuse makes code harder to read. (One register being used to store either adress, a point coordinates, etc.)

*  Solidity being a recent language, the capacity of inlining of the compilator solc remains low. For this reason the ecmulmuladd is a quite indigest large block of code.

## Files to be audited


| Name                  | Note                                                                           |
|-----------------------|---------------------------------------------------------------------------------|
libSCL_rip7212.sol | rip7212 implementation
SCL_ecdsaW.sol            | 	ecdsa verification            |               
|    SCL_mulmuladd_gen_windowed.sol                   |    Shamir's trick+windowing           |                  
libSCL_ripb4.sol | ripB4 implementation
SCL_mulmuladd_fullgen_b4.sol            | 	Shamir's trick with 4 input           |    



## Test Strategy

The library is tested against wycheproof test vectors. Project Wycheproof tests crypto libraries against known attacks. It is developed and maintained by members of Google Security Team, but it is not an official Google product.


## Non Disclosure Agreement

By participating to the audit of SCL, CryptoExperts agree to the general Smoo.th non disclosure agreement conditions.


## Reference

* [NIST-SP86] Digital Signature Standard (DSS). https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-5.pdf
* [RD23] Speeding up elliptic computations for Ethereum Account
Abstraction. https://eprint.iacr.org/2023/939 
* [RIP7212] Proposal to add precompiled contract that performs signature verifications in the “secp256r1” elliptic curve. https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7212.md
* [RIPB4] Proposal to add precompiled contract that performs generic double point multiplication and accumulation. (WIP)
* [WYCHEPROOF] Project Wycheproof. https://github.com/C2SP/wycheproof
