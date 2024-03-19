---
rip: 
title: Precompile for generic bilinear point multiplication
description: Proposal to add precompiled contract that performs two point multiplication and an addition over any elliptic curve.
author: Renaud Dubois (@rdubois-crypto)
discussions-to: todo
status: Draft
type: Standards Track
category: Core
created: 2024-03-22
---

## Abstract

This proposal creates a precompiled contract that performs two point multiplication and sum then over any elliptic curve by given parameters of `p`, `a`,`b` curve parameters,  and `Px1`,`Py1`,`Qx2`,`Qy2` coordinates of points  P and Q. Thus it computes the value uP+vQ over any given weierstrass curve.

## Motivation

There are many elliptic curves of interest and those are subject to change according to latest advances either in ZK proving systems, hardware integration or cross chains requirements. This precompiles can achieve many goals such as Stealth, WebAuthn, Schnorr signatures.

For example:


1. **ed25519:**


2. **secp256r1:** Apple secure enclave, Android Keystore, Passkeys, Webauthn, OpenSSL

3. **bn254:**

4. **bls12381:**

5. **Baby Jujub:** 

6. **Stark curve:** 

Modern devices have these signing mechanisms that are designed to be more secure and they are able to sign transaction data, but none of the current wallets are utilizing these signing mechanisms. So, these secure signing methods can be enabled by the proposed precompiled contract to initiate the transactions natively from the devices and also, can be used for the key management. This proposal aims to reach maximum security and convenience for the key management.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

As of `FORK_TIMESTAMP` in the integrated EVM chain, add precompiled contract `P256VERIFY` for signature verifications in the “secp256r1” elliptic curve at address `PRECOMPILED_ADDRESS` in `0x100` (indicates 0x0000000000000000000000000000000000000100).

### Elliptic Curve Information

“secp256r1” is a specific elliptic curve, also known as “P-256” and “prime256v1” curves. The curve is defined with the following equation and domain parameters:

```
# curve: short weierstrass form
y^2 ≡ x^3 + ax + b

# p: curve prime field modulus

# a: elliptic curve short weierstrass first coefficient

# b: elliptic curve short weierstrass second coefficient

# P1: first point of the subgroup

# P2: first point of the subgroup
# n: subgroup order (number of points)

```

### Elliptic Curve  ecmulmuladd Steps


### Required Checks in Verification

The following requirements **MUST** be checked by the precompiled contract to verify signature components are valid:


### Precompiled Contract Specification

The `ecMulmuladd` precompiled contract is proposed with the following input and outputs, which are big-endian values:

- **Input data:** 160 bytes of data including:
    - 32 bytes of the signed data `hash`
    - 32 bytes of the `r` component of the signature
    - 32 bytes of the `s` component of the signature
    - 32 bytes of the `x` coordinate of the public key
    - 32 bytes of the `y` coordinate of the public key
- **Output data:** 32 bytes of result data and error
    - If the signature verification process succeeds, it returns 1 in 32 bytes format.

### Precompiled Contract Gas Usage

The use of signature verification cost by `ecMulmuladd` is `3000` gas. Following reasons and calculations are provided in the [Rationale](#rationale) and [Test Cases](#test-cases) sections.

## Rationale

## Backwards Compatibility

No backward compatibility issues found as the precompiled contract will be added to `PRECOMPILED_ADDRESS` at the next available address in the precompiled address set.

## Test Cases


## Reference Implementation

Implementation of the `ecMulmuladd` precompiled contract is provided as a progressive precompile. A king of the hill contest is organized to challenge the provided implementation.

## Security Considerations

The changes are not directly affecting the protocol security, it is related with the applications using `P256VERIFY` for the signature verifications. The “secp256r1” curve has been using in many other protocols and services and there is not any security issues in the past.


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
