# SmoothCryptoLib (SCL)
A Cryptographic Library for Smooth Blockchain uses.


## Compilation

Clone the repository, then type `forge test`.


## Deployment

Run deploy.sh to deploy the code on a target chain. 
The values `$RPC` and `$CHAINID` shall be set to the chain ones. 
The toy private and public key shall be replaced and funded (current can be used for testnet). 



## Benchmarks


### Forge results

The benchmarks are performed by averaging forge results over a loop of 100 tests. Be sure to avoid the use of -via-IR and set foundry.toml correctly to reproduce correct measurements.

| curve | Function  | gas | Comment | File| 
|--------:|---------|:--:|:----|:----|
| P256 | SCL_ECDSAB4.verify   | 159K  | ECDSA using RIP7696 (second opcode)  | libSCL_ECDSAb4.sol |
||         |  |         ||



### Onchain results


| PR # | Create2 | Mainnets | Testnets |
|--------:|---------|:--:|:----|
|[N/A](https://github.com/rdubois-crypto/FreshCryptoLib/pull/46)| 0x05eFAC4C53Ec12F11f144d0a0D18Df6dfDf83409    | |  [Sepolia](https://sepolia.etherscan.io/address/0x05eFAC4C53Ec12F11f144d0a0D18Df6dfDf83409#code) ,[Optimism](https://sepolia.etherscan.io/address/0x05eFAC4C53Ec12F11f144d0a0D18Df6dfDf83409#code) |  
||         |  |         |



# Audits 


| Team    | branch  |  status |
|--------:|---------|:--:|
| CryptoExperts | CryptoExperts   | In Progress |


# Curves implementation status



| curve | status  | branch | Comment | File| 
|--------:|---------|:--:|:----|:----|
| P256 | OK   | main  | ECDSA using RIP7696 (second opcode)  | libSCL_ECDSAb4.sol |
| Ed25519|     WIP    | experimental |    ECC OK, SHA512 long vectors missing     ||

# Acknowledments

The following work has been half-funded by the Ethereum Fundation grant number FY24-1386:
 * ed25519 solidity (work in progress)

SCL is build by the same team of the previous FCL. As such all previous contributors are credited.


## License 
License: This software is licensed under MIT License (see LICENSE FILE at root directory of project).