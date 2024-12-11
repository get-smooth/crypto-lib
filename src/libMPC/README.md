# SmoothCryptoLib (SCL)
A Cryptographic Library for Smooth Blockchain uses.

This repository is a private fork of the audited SCL. In addition to SCL generic ECC solidity, 
it contains the actual experiments around Musig2 and FROST.


## Design

The aim of the Smooth-LibMPC is to provide an open source implementation of 
- Musig2: is a MPC scriptless algorithm, specified in BIP327, it is part of Taproot and enables n out of n signature,
- Atomic Swaps: use adaptator signatures to enable trustless bridges, requires Musig2,
- FROST is a threshold signature scheme (k out of n), which enables governance, without requiring to deploy on chain contract, providing more privacy on the governance.


The SmoothMPCLib consists in two parts:
- An onchain solidity verifier, implemented in libSCL_BIP327.sol as part of SCL (Smoo.th Crypto Lib)
- A javascript implementation of signer side to be integrated into any webApp leveraging the targeted protocol. 

### Features

- Compatibility with BIP340 : When curve is set to 'secp256k1', the result of the MPC procedure passes BIP340 verification for the BIP340 X-only version of the group public key and a message.
- Compatibility with RFC8032 : When curve is set to 'ed25519', the result of the MPC procedure passes RFC8032 verification for the compressed signature version.


### Implementation status



| Protocol | status  | branch | Comment | File| 
|--------:|---------|:--:|:----|:----|
| Onchain Verifier | OK   | main  |   | libSCL_BIP327.sol (secp256k1), libSCL_RIP6565.sol (ed25519) |
| Musig2-secp256k1 | OK   | main  |   | bip327.mjs or SCL_Musig2.mjs |
| Musig2-ed25519 | OK   | main  |   |  SCL_Musig2.mjs|
| Atomic Swaps | OK   | main  | | SCL_atomic_swaps.mjs |
| Frost|     OK    | main |  |  SCL_frost.mjs       |
|



## Installation


### Javascript (signer) library

It is necessary to install noble-curves, which the library is based on for the elliptic primitives function.

`npm install @noble/curves`

Test of BIP327 can be run typing  `node test_bip327.mjs`.
The test includes the BIP327 test vectors, enforcing compatibility of the signer with BTC, and any 4337/7702 integrating the libSCL_BIP327.sol verifier.

### Compile Solidity lib
Clone the repository, then type `forge test`. (Some troubles are solved running `foundryup` and `forge init --force`).


#  libMPC Musig2


## Background 

Musig2 is a MPC signature protocol in which $n$ signers collaborates to produce a valid Schnorr signature (indistinguishable from a single signer) without revealing any private element. As such it provides privacy (individual public keys are not revealed), efficiency (only one required on chain element) and many potential use cases (one being the untrapdoorable wallet).


## Session example

### Description 
A 2 of 2 session is described here. It generalizes identically with larger user set.
We use BIP327 with no tweak.

Prior to any use, an object of type SCL_Musig2 must be initialized with one of the supported curve.

```
    const curve = 'secp256k1'; 
    const signer = new SCL_Musig2(curve);
```
curve can also be configured to 'ed25519'.

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

# libMPC - Atomic Swap

## Background 

An atomic swap is a process allowing two users to exchange information/token from distinct chains. While it is possible to use a basic 'hash locked mechanism', such a process reveals information about the swap, it also requires a script. Using Musig2, it is possible to provide the functionnality but disabling the possibility to link the transactions on each chain. With liquidity, atomic swaps provide a building block to provide a permissionless bridge.

## Session example

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

To reduce the complexity for developpers, the library provides state machine for the initiator and responder of the swap.
Each of the previous exchange between a message from Alice to Bob.

```
 //generating keypairs
    let Initiator=new SCL_Atomic_Initiator(curve, signer.curve.Get_Random_privateKey());
    let Responder=new SCL_Atomic_Responder(curve, signer.curve.Get_Random_privateKey());

    //the transaction unlocking tokens for Alice and Bob, must be multisigned with Musig2
    //Alice want to compute msg1 signed by AB
    //Bob wants to compute msg2 signed by AB
    const tx1=Buffer.from("Unlock 1 BTC on bitcoin to Alice",'utf-8');
    const tx2=Buffer.from("Unlock 1WBTC on Ethereum to Bob",'utf-8');


    console.log("Initiator Start session");
    let Message_I1=Initiator.InitSession(tx1, tx2); //Initiator sends I1 to responder offchain

    console.log("Responder Start session");
    let Message_R1=Responder.RespondInit(Message_I1);//Respondeur sends R1 to Initiator offchain

    console.log("Initiator Partial Sign and tweak");
    let Message_I2=Initiator.PartialSign_Tweaked(Message_R1);//Initiator sends I2 to responder offchain
    //At this Point Alice and Bob locks the funds to multisig address on chain 1 and chain 2

    console.log("Responder Check and Partial Sign");
    let Message_R2=Responder.PartialSign(Message_I2);//Respondeur sends R2 to Initiator offchain

    console.log("Initiator Signature Aggregation and Unlock");
    let UnlockSigAlice=Initiator.FinalUnlock(Message_R2);//final signature to Unlock chain1 token by Initiator

    console.log("Responder Signature Aggregation and Unlock");
    let UnlockSigBob=Initiator.FinalUnlock(UnlockSigAlice);//final signature to Unlock chain2 token by Responder
```

Note: the protocol requires to broadcast onchain 4 values (2 locked tokens, then two unlocking signatures). 

### Improving privacy

- $P_A, P_B$ and $P_{AB}$ might differ on chain 1 and 2.
- Using a zk-proof of Discrete Log, it is possible to use a different curve on chain1 and chain2.

### Improving security

The element $t$ shall be as protected as a secret key, to prevent $B$ from stealing $A$ token. In the description, Alice has more duty regarding to the protection of this secret. 


# libMPC - FROST


## Background 

FROST is a TSS (threshold signature scheme), enabling a 'm out of n' authentication. n users owns a private key tied to a secret polynomial generated during an initial phase (which can be centralized or not). The group key, indistinguishable from a classic Schnorr (Taproot) key is the evaluation of this polynomial at origin. Later on, when m users colludes, they are able to create a signature for a given message without revealing their share.

In simpler terms, FROST provides a 'm out of n' authentication, without revealing the interaction between signers, keeping governance private.
 It can be used as a privacy enhancement for contracts like [Safe](https://app.safe.global/welcome/accounts). It can also be used to provide a private policy management for recovery.


## Session example
The following describes a full session.
Related code is available in `test_random_fullsession()` which generates random input and select a random subset of size k+1 from the n users to perform a session.

### Key generation

For now the generation use a 'secret sharing' like key generation. It is implemented in the  `SCL_trustedKeyGen` class.
```
    let curve=new SCL_ecc(Curvename);
    let sk=curve.Get_Random_privateKey();
    let dealer=new SCL_trustedKeyGen(Curvename,sk, n,k);

    //provide shares to users:
    let b8_pubshares=elements.map(index => curve.PointCompress(dealer.pubshares[index]))
    let secshares=elements.map(index => dealer.secshares[index]);
    
```
Curvename can be set to either 'secp256k1' or 'ed25519'.
The input of the generation are the curvename ('secp256k1' or 'ed25519' for now), the private key of the dealer, the maximal number of users, and the degree of the polynomial (the number of minimal participants to authenticate minus 1).
Once initialized, the structure contains the secret shares and public  shares of users, to be distributed through a safe channel.

### Generating nonces and aggregation

Each user generates its nonce, and shares to others (or an aggregator) its public part
```
 for(let i=0;i<k+1;i++){
        let nonce=frost.Nonce_gen( int_to_bytes(secshares[i][1],32), b8_pubshares[i], group_pk, msg, extra_in );
        secnonces.push(nonce[0]);
        pubnonces.push(nonce[1].toString('hex'));
    }
```
The public nonces are then aggregated
```
    let aggnonce=frost.Nonce_agg(pubnonces)
```

### Partial signatures

Once the aggregated nonce is known to everyone, each signer process its partial signature:
```
let psigs=[];
    for(let i=0;i<k+1;i++){
        let psig=frost.Psign(secnonces[i], int_to_bytes(secshares[i][1],32), Ids[i], session_context);
        console.log("psig:", psig);
        psigs.push(psig);
    }
```

### Signature aggregation

Once all partial signatures are computed, they can be aggregated to produce the final signature to broadcast on chain:
```
let final_sig=frost.Partial_sig_agg(psigs, Ids, session_context);
```
It can be verified that the resulting signature is compliant to BIP140(secp256k1 on BTC) or RFC8032 (Yubikey, Cosmos, Solana)

```
console.log("final verif:", frost.Schnorr_verify(msg, x_group_pk,final_sig ));
```

## Design notes

The generation and distribution of FROST's shares are out of scope of its specification. However 
[FROST-RFC](https://datatracker.ietf.org/doc/draft-irtf-cfrg-frost/15/) specifies a trusted key dealer generation which is the most obvious. The DKG is implemented in the class SCL_trustedkeygen.
In the future the more decentralized chill-DKG shall be implemented.




# Testing

## Musig2

Tests can be ran using the following command :
```
    node test_Musig2.mjs
```
Tests are run against BIP327 reference vectors to unitary test each function.
Then a full Musig2 session is ran using dynamically generated input for each supported curve.


## Atomic Swap

Tests can be ran using the following command :
```
    node test_atomic_swap.mjs
```

## Bridging (WIP)

The `file test_atomic_bitcoin.js` aims to provide a full onchain demonstration of a bridging.


## FROST

Tests can be ran using the following command :
```
    node test_frost.mjs
```


# Product Roadmap

- Musig2 can be used to provide protection against trappoored hardware [as explained here](https://docs.google.com/presentation/d/10JmRVq9qeoIouLyzIOMcMLnfQQbZlZoSP5eTOyXYUdI/edit#slide=id.g2bf9c14683d_1_265). Using Musig2 with account abstraction, it is possible to have a companion app handling a first key, the hardware wallet a second.
- Atomic swaps enables trustless bridging between non EVM chains. We are gonna use this library to provide trustless bridge with EVM, Starknet and BTC, and later with Cosmos and Solana using the Ed25519 version.
- FROST can be used to make an invisible governance in a Vault application. While SCL passkey module (using 7212) makes traditional single owner invisible, using FROST, it is the Safe itself that can be concealed.




## References
https://github.com/BlockstreamResearch/scriptless-scripts/blob/a8b6ff21fc7f4529eabbe639fbff49f047a3579d/md/musig2-adaptorsig.md
https://github.com/BlockstreamResearch/scriptless-scripts/blob/master/md/atomic-swap.md
https://eprint.iacr.org/2021/150.pdf

# Relation with Prior work

While ecrecover enables an efficient implementation of Schnorr signatures, there is no trivial way to implement atomic swaps with Solana and Cosmos ecosystems. RIP7696 genericity solves the need for ed25519, avoiding to use complex zk-proof to prove discrete log equivalence.


## Acknowledgment



## License 
License: This software is licensed under MIT License (see LICENSE FILE at root directory of project).
