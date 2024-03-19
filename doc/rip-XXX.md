---
rip: 
title: Precompile for generic bilinear point multiplication (ecmulmuladd)
description: Proposal to add precompiled contract that performs two point multiplication and an addition over any elliptic curve.
author: Renaud Dubois (@rdubois-crypto)
discussions-to: todo
status: Draft
type: Standards Track
category: Core
created: 2024-03-22
---

## Abstract

This proposal creates two precompiled contracts that perform two point multiplication and sum then over any elliptic curve  given `p`, `a`,`b` curve parameters,   `Px1`,`Py1` and`Qx2`,`Qy2` coordinates of points  P and Q, `u`,`v` two scalars. Thus it computes the value uP+vQ over any given weierstrass curve. One of the precompiles provide extra data (512 bits) to enable a GLV comparable speed-up to any curve. This extra data consists in the points P128=$2^{128}P$ and Q128=$2^{128}Q$.



## Motivation

There are many elliptic curves of interest and those are subject to change according to latest advances either in ZK proving systems, hardware integration or cross chains requirements. This precompiles can achieve many goals such as Stealth, WebAuthn, Schnorr signatures. While most authentication scheme relies today on ECDSA, Schnorr versions are more MPC and ZK-friendly (faster and more secure).

For example:

1. **ed25519:** Apple secure enclave,  Webauthn, OpenSSL, Farcaster.

2. **secp256r1:** Most of previous use cases plus Android Keystore, Passkeys.

3. **bn254:** Zcash, Tornado Cash.

4. **Baby Jujub:** Circom.

5. **Stark curve:** Starknet Ecosystem.

6. **Other curve:** Pasta, Vela, sec256q1 for inner argument constructions.


This proposal aims to reach maximum security and cryptographic agility for the key management.

## Specification

### Constants

| Name                  | Value                                                                           |
|-----------------------|---------------------------------------------------------------------------------|
| FORK_BLOCK            | 	TBD                    
| ECMULMULADD_COST            |  3500
| ECMULMULADD_B4_COST            |  2000
                                                                               
### New Precompile
#### Elliptic Curve Information

Any elliptic curve can be expressed under a Weierstrass form defined by the equation $y^2 ≡ x^3 + ax + b \mod p.$ The minimal information of domain parameters required for ecmulmuladd is defined with the following equation and domain parameters:


| Name                       | Value                                                                        |
|----------------------------|------------------------------------------------------------------------------|
| p                     | modulus of the elliptic prime field                     |
| a                      |elliptic curve short weierstrass first coefficient                          |
| b                  | elliptic curve short weierstrass second coefficient |





### Required Checks in Verification

The following requirements **MUST** be checked by the precompiled contract to verify signature components are valid:
- P and Q coordinates verify the curve equation,
- P and Q coordinates are within prime field range (i.e belong to [0..p-1]).

The following elements are NOT checked by the precompile:
 - the provided curve is safe regarding classic criteria (twist security, embedded degree, rho security, etc.)
 - the provided points belongs to the right subgroup (for non prime order curves)

As such it is heavily recommended to avoid custom curves without an extended knowledge and examination of the previous criterias.

### Precompiled Contracts Specification

The `ecMulmuladd` precompiled contract is proposed with the following input and outputs, which are big-endian values:

- **Input data:** 224 bytes of data including:
    - 32 bytes of the modulus $p$
    - 32 bytes of the `a` component of the signature
    - 32 bytes of the `b` component of the signature
    - 32 bytes of the `Px` x coordinate of the first point
    - 32 bytes of the `Py` y coordinate of the first point
    - 32 bytes of the `Qx` x coordinate of the first point
    - 32 bytes of the `Qy` y coordinate of the first point

- **Output data:** 64 bytes of result data and error
    - If the ecmulmuladd process succeeds, it returns the resulting point as 64 bytes of data. The infinity point (neutral for addition law) is represented as the (0,0) couple.
    - In case of failure it returns an empty chain

The `ecMulmuladd_b4` precompiled contract is proposed with the following input and outputs, which are big-endian values:

- **Input data:** 352 bytes of data including:
    - 32 bytes of the modulus $p$
    - 32 bytes of the `a` component of the signature
    - 32 bytes of the `b` component of the signature
    - 32 bytes of the `Px` x coordinate of the first point P
    - 32 bytes of the `Py` y coordinate of the first point Q
    - 32 bytes of the `P128x` x coordinate of the first point P128=$2^{128}P$  
    - 32 bytes of the `P128y` y coordinate of the first point  P128=$2^{128}P$  
    - 32 bytes of the `Qx` x coordinate of the first point Q128=$2^{128}Q$
    - 32 bytes of the `Qy` y coordinate of the first point  Q128=$2^{128}P$  
    - 32 bytes of the `Q128x` x coordinate of the first point P128=$2^{128}P$  
    - 32 bytes of the `Q128y` y coordinate of the first point  P128=$2^{128}P$  
    


- **Output data:** 64 bytes of result data and error
    - If the ecmulmuladd process succeeds, it returns the resulting point as 64 bytes of data. The infinity point (neutral for addition law) is represented as the (0,0) couple.
    - In case of failure it returns an empty chain

### Implementation 

The node is free to implement the elliptic computations as it see fit (choice of inner elliptic point reprensentation, ladder, etc). For perfomances reasons, it is recommended to use the so called Strauss-Shamir's trick (with a 4 dimensional version for ecmulmuladd_b4). Use of windowing and NAF can speed-up implementation further.


### Precompiled Contract Gas Usage

- The cost of `ecMulmuladd` is `4000` gas. It is related to the increased cost of the extra call data to a specialized implementation, taking the best pure solidity implementation available for generic curves, which is 10% according to our measures.

- The cost of `ecMulmuladdB4` is `2500` gas. It is the ratio between ecMulmuladd implementation gas cost with and without the extra call data.
               

## Backwards Compatibility

No backward compatibility issues found as the precompiled contract will be added to `PRECOMPILED_ADDRESS` at the next available address in the precompiled address set.

## Test Cases


## Reference Implementation

Implementation of the `ecMulmuladd` precompiled contract is provided as a progressive precompile. A king of the hill contest is organized to challenge the provided implementation.

## Security Considerations

The changes are not directly affecting the protocol security. The security is related to the level of investigation the target curve has been through.


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
