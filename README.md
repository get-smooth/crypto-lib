# SmoothCryptoLib
A Cryptographic Library for Smooth Blockchain uses.


## Compilation

Clone the repository, then type `forge test`.




## Benchmarks


### Forge results

The benchmarks are performed by averaging forge results over a loop of 100 tests. Be sure to avoid the use of -via-IR and set foundry.toml correctly to reproduce correct measurements.

| curve | Function  | gas | Comment | File| 
|--------:|---------|:--:|:----|:----|
| P256 | SCL_ECDSAB4.verify   | 159K  | ECDSA using RIP7696 (second opcode)  | libSCL_ECDSAb4.sol |
||         |  |         ||



### Onchain results
WIP
# Acknowledments

The following work has been half-funded by the Ethereum Fundation grant number FY24-1386:
 * ed25519 solidity (work in progress)


## License 
License: This software is licensed under MIT License (see LICENSE FILE at root directory of project).