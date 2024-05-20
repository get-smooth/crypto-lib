# Optimization Suggestions for Non-Native ECC in Cairo0



##  Motivations

[RIP 7696](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7696.md) introduces a proposal to provide a standardized precompiles to handle them all. This precompile would allow a wide variety of curves such as Ed25519, babyjujub, palla, vesta, etc.

This note describes the required hints to implement RIP7696, to provide both generic curves handling, with two algorithmic improvments to speed up further computations.

## 1) Nature of Required Hints:

To answer your question about the necessary hints, in reality, it would be sufficient to make the existing traits in `ec.cairo` and `field.cairo` generic.

This means replacing each occurrence of `alpha=SECP256R1_ALPHA` or `p=SECP256R1_P` with `alpha=ids.alpha`, `p=ids.p`.

## 2) Concerned Occurrences:

- [Line 30](https://github.com/starkware-libs/cairo-lang/blob/efa9648f57568aad8f8a13fbf027d2de7c63c2c0/src/starkware/cairo/common/secp256r1/ec.cairo#L30)
- [Line 73](https://github.com/starkware-libs/cairo-lang/blob/efa9648f57568aad8f8a13fbf027d2de7c63c2c0/src/starkware/cairo/common/secp256r1/ec.cairo#L73)
- [Line 125](https://github.com/starkware-libs/cairo-lang/blob/efa9648f57568aad8f8a13fbf027d2de7c63c2c0/src/starkware/cairo/common/secp256r1/ec.cairo#L125)
- [Line 208](https://github.com/starkware-libs/cairo-lang/blob/efa9648f57568aad8f8a13fbf027d2de7c63c2c0/src/starkware/cairo/common/secp256r1/ec.cairo#L208)
- [Line 371](https://github.com/starkware-libs/cairo-lang/blob/efa9648f57568aad8f8a13fbf027d2de7c63c2c0/src/starkware/cairo/common/secp256r1/ec.cairo#L371)
- [Line 401](https://github.com/starkware-libs/cairo-lang/blob/efa9648f57568aad8f8a13fbf027d2de7c63c2c0/src/starkware/cairo/common/secp256r1/ec.cairo#L401)

(Similarly, lines 125, 169, and 198 in `field.cairo`).

## 3) Efficiency of Non-Native Signature Implementation:

There is a 33% asymptotic gain possible in how `ec.cairo` is implemented in cairo0 by using 2MSM instead of the current window4 method.

In [RIP 7696](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7696.md) also proposes a second opcode that brings the gain to 50% with 4MSM. It is independant of the language used and could benefit Starknet ecc implementation.

## 4) Applicability

By taking the parameters as input, we can handle Ed25519 and P256, stark, babyjujub with the same cairo0 precompile. (As done in Solidity RIP assets https://github.com/ethereum/RIPs/pull/20). There will likely be a slight loss due to memory accesses for the parameters, which are negligible compared to the switch to 2MSM. As of 20/5/24, Ed25519 in Cairo1 is more than 3M steps, while Cairo0 implementation is around 300K.