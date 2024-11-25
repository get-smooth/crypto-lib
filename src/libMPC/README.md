# SmoothCryptoLib (SCL)
A Cryptographic Library for Smooth Blockchain uses.

This repository is a private fork of the audited SCL. In addition to SCL generic ECC solidity, 
it contains the actual experiments around Musig2 and FROST.


## Description

The aim of the Smooth-LibMPC is to provide an open source implementation of 
- Musig2: is a MPC scriptless algorithm, specified in BIP327, it is part of Taproot and enables n out of n signature,
- Atomic Swaps: use adaptator signatures to enable trustless bridges, requires Musig2,
- FROST is a threshold signature scheme (k out of n), which enables governance, without requiring to deploy on chain contract, providing more privacy on the governance.


The SmoothMPCLib consists in two parts:
- An onchain solidity verifier, implemented in libSCL_BIP327.sol as part of SCL (Smoo.th Crypto Lib)
- A javascript implementation of signer side to be integrated into any webApp leveraging the targeted protocol. 


### Implementation status



| Protocol | status  | branch | Comment | File| 
|--------:|---------|:--:|:----|:----|
| Onchain Verifier | OK   | main  |   | libSCL_BIP327.sol |
| Musig2-secp256k1 | OK   | main  |   | bip327.mjs |
| Musig2-ed25519 | TBD   | -  |   |  |
| Atomic Swaps | In progress   | -  | | SCL_atomic_swaps.mjs |
| Frost|     TBD    | - |  |         |
|



## Installation


### Javascript (signer) library

It is necessary to install noble-curves, which the library is based on for the elliptic primitives function.

`npm install @noble/curves`

Test of BIP327 can be run typing  `node test_bip327.mjs`.
The test includes the BIP327 test vectors, enforcing compatibility of the signer with BTC, and any 4337/7702 integrating the libSCL_BIP327.sol verifier.

### Compile Solidity lib
Clone the repository, then type `forge test`. (Some troubles are solved running `foundryup` and `forge init --force`).


# Performing a Multisignature with libMPC Musig2


A 2 of 2 session is described here. It generalizes identically with larger user set.
We use BIP327 with no tweak.

Prior to any use, an object of type SCL_Musig2 must be initialized with one of the supported curve.

```
    const curve = 'secp256k1';
    const signer = new SCL_Musig2(curve);
```


### Key generation and aggregation

First, user1 and user2 generates their private key, or import them from seed. 
```
    const sk1=secp256k1.utils.randomPrivateKey();//this provides a 32 bytes array
    const sk2=secp256k1.utils.randomPrivateKey();
```

Corresponding aggregated key is derived from public keys:
```
 const pubK1=signer.IndividualPubKey_array(sk1);   
 const pubK2=signer.IndividualPubKey_array(sk2);

 
 let aggpk = signer.Key_agg(pubkeys)[0];//here aggpk is a 33 bytes compressed public key
 let x_aggpk=aggpk.slice(1,33);//x-only version for noncegen
```
(of course in practice derivation occurs separately in each signer secure domain)


### Signature session

Assuming user generated their public key according to previous section, they now want to jointly sign a message `msg`. An example session is provided [here](https://github.com/rdubois-crypto/UnruggableWallet/blob/66b84ec4f807919dd443907463318fac0ac1b5f5/src/libMPC/test_bip327.mjs#L290). 

#### Round 1
In first round, user1 and user2 generates public and secret nonces. Public are shared, secret keep in respective secure domain.

```
   
    const nonce1=signer.Nonce_gen_internal(rand1, sk1, pubK1, x_aggpk, msg, Buffer.from("00000000", 'hex'));
    const nonce2=signer.Nonce_gen_internal(rand2, sk2, pubK2, x_aggpk, msg, Buffer.from("00000000", 'hex'));

    let aggnonce = signer.Nonce_agg([nonce1[1].toString('hex'), nonce2[1].toString('hex')]);
```

#### Round 2
In second round, each user computes its partial signature, which are then aggregated and broadcast on chain:

```
    const tweaks=[];
    const session_ctx=[aggnonce, pubkeys, [], [], msg];

    let p1=signer.Psign(nonce1[0], sk1, session_ctx);
    let p2=signer.Psign(nonce2[0], sk2, session_ctx);
      
    let psigs=[p1,p2];
  
    let res=signer.Partial_sig_agg(psigs, session_ctx);
```
res is the final results to push onchain. One can check the correctness in front before pushing the results:

```
      let check=signer.Schnorr_verify(msg, x_aggpk, res);
      console.log("check=", check);
```

# Performing an atomic swap

The description doesn't include the timelock on both chains, which cancel the deposits if Alice and Bob didn't succeed in their withdrawal.
Abortion of one of the participant is the only way the protocol shall fail, which is resolved by the timelock condition of withdrawal.
By convention chain1 is the chain with the lowest `chainID`.


The sequencing of a Musig2 based atomic swap session is as follow:
- Alice and Bob owns respective key pairs $(sk_a, Q_A)$ and $(sk_b, Q_B)$ 
- $P$ is the multisig public key computed with `key_agg`,
- A sends 1 token to AB **on chain 2**, B sends 1 token to AB **on chain 1**, both are timelocked (refund if protocol fails),
- A and B agrees offchain on R1 and R2 using `nonce_gen_internal` and `nonce_agg`. First nonce R1 is used for chain1, second R2 for chain2. Corresponding Alice and Bob secnonces are denoted as rA1, rA2, rB1, rB2.
- A chooses a random tweak t, and computes the tweaked partial signature with `psign` then using t as tweak adaptator:
  * Alice signs and broadcast off chain $T=tG$, $s'_A1=(t+ra_1)G+H(R, P, m_1)sk_A$, where $m_1$ is the transaction sending coins from AB to A using `psign_adapt`. t is kept secret by Alice.
  * Using the same $t, T$, alice signs and broadcast off chain $s'A2=(t+ra_2)G+H(R, P, m_2)sk_A$ where $m_2$ is the transaction sending coins from AB to B.
- B checks the compliance of $T, s'_A1, s'_A2$ using `atomic_check`
- B signs and broadcast off chain partial signature $s_B1=rb.G+H(P,R,m_1)P_B$  with `psign`
- knowing $t, S_A1, S_B1$ A computes $S_{AB}$ the Musig2 signatures of $m_1$ using `sign_untweak`, and broadcast it **on chain** 1.
- B reads the value $S_{AB}$ on chain 1, learns t, then broadcast **on chain 2** $S_{AB}(m_2)$ using `sign_untweak` on chain 2 to unlock its token.

Note: the protocol requires to broadcast onchain 4 values (2 locked tokens, then two unlocking signatures). 

### Improving privacy

- $P_A, P_B$ and $P_{AB}$ might differ on chain 1 and 2.
- Using a zk-proof of Discrete Log, it is possible to use a different curve on chain1 and chain2.

### Improving security

The element $t$ shall be as protected as a secret key, to prevent $B$ from stealing $A$ token. In the description, Alice has more duty regarding to the protection of this secret. 




# Product Roadmap

- Musig2 can be used to provide protection against trappoored hardware [as explained here](https://docs.google.com/presentation/d/10JmRVq9qeoIouLyzIOMcMLnfQQbZlZoSP5eTOyXYUdI/edit#slide=id.g2bf9c14683d_1_265). Using Musig2 with account abstraction, it is possible to have a companion app handling a first key, the hardware wallet a second.
- Atomic swaps enables trustless bridging between non EVM chains. We are gonna use this library to provide trustless bridge with EVM, Starknet and BTC, and later with Cosmos and Solana using the Ed25519 version.
- FROST can be used to make an invisible governance in a Vault application. While SCL passkey module (using 7212) makes traditional single owner invisible, using FROST, it is the Safe itself that can be concealed.





# Similar work

Since the publication of our roadmap, 

## References
https://github.com/BlockstreamResearch/scriptless-scripts/blob/a8b6ff21fc7f4529eabbe639fbff49f047a3579d/md/musig2-adaptorsig.md
https://github.com/BlockstreamResearch/scriptless-scripts/blob/master/md/atomic-swap.md
https://eprint.iacr.org/2021/150.pdf

# Relation with Prior work

While ecrecover enables an efficient implementation of Schnorr signatures, there is no trivial way to implement atomic swaps with Solana and Cosmos ecosystems. RIP7696 genericity solves the need for ed25519, avoiding to use complex zk-proof to prove discrete log equivalence.


## Acknowledgment



## License 
License: This software is licensed under MIT License (see LICENSE FILE at root directory of project).
