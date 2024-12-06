/********************************************************************************************/
/*
/*     ___                _   _       ___               _         _    _ _    
/*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
/*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
/*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
/*                                         |__/|_|           
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
/* License: This software is licensed under MIT License                                        
/********************************************************************************************/

import {  secp256k1 } from '@noble/curves/secp256k1'; 
import{atomic_example} from './SCL_atomic_swaps.mjs';
import * as secp from 'tiny-secp256k1';
import fetch from 'node-fetch';//npm install node-fetch

// Initialize the ECC library with TinySecp256k1
import { ECPairFactory } from 'ecpair';

const ECPair = ECPairFactory(secp);

import  * as bitcoin from 'bitcoinjs-lib';//npm install bitcoinjs
bitcoin.initEccLib(secp);

//const ECPair = ECPairFactory(ecc);

//import { Signer, SignerAsync, ECPairInterface, ECPairFactory, ECPairAPI, TinySecp256k1Interface } from 'ecpair';

// Set up ECPair with tiny-secp256k1 as required by ECPairFactory
//const ECPair = ECPairFactory(ecc);

const network = bitcoin.networks.testnet;
//atomic_example();
const privateKey = secp256k1.utils.randomPrivateKey();
const publicK= secp256k1.getPublicKey(privateKey, true);
console.log('key',privateKey);


console.log('key pub',publicK);
console.log(Object.keys(ECPairFactory));

const keyPair = ECPair.fromPrivateKey(Buffer.from(privateKey), { network });
console.log('key',keyPair);
console.log('key pub',publicK);

console.log('Private Key (WIF):', keyPair.toWIF());
const { address } = bitcoin.payments.p2tr({ pubkey: publicK.slice(1,33), network: bitcoin.networks.testnet });

console.log('Testnet Address:', address);

const tx = new bitcoin.Psbt({ network: bitcoin.networks.testnet }); // Use Psbt for transaction creation
// Define UTXO to spend
const txId = '62d9b44b6a6268bd4a74ab2141133343849f012b694e0ff7c32b0b3f5e3c87fa'; // Replace with the transaction ID of the UTXO to spend
const vout = 0; // The output index of the UTXO
const amountToSend = 1 * 1e1; // 1.10-7 BTC in satoshis
tx.addInput({
    hash: txId, // Transaction ID of the UTXO
    index: 0, // Output index within the transaction
    witnessUtxo: {
        script: Buffer.from('0014d85a4e1a2b1d8f27c405b5b5d715b2f23f3ddcc3', 'hex'), // P2WPKH script or appropriate script for your UTXO type
        value: amountToSend, // Value of the UTXO in satoshis
    },
});

tx.addOutput("1Gokm82v6DmtwKEB8AiVhm82hyFSsEvBDK", amountToSend);
const sighash = tx.hashForSignature(0, p2tr.output, Transaction.SIGHASH_ALL);
const signature = secp.signSchnorr(sighash, privateKey);
console.log("Schnorr Signature:", signature.toString('hex'));

    // Build the transaction without signing it
    const txInc = tx.buildIncomplete();
/*
key Uint8Array(32) [
    240, 165,  76, 109, 221,  29, 213, 231,
    139, 138, 178, 140, 161,  87,  32, 101,
    172,  31, 194, 164, 114, 186,  31,  96,
     65, 226,   8,  13, 225,  64, 163,  69
  ]
  key pub Uint8Array(33) [
      2, 248,  59,  32, 158, 235,  60, 129,
    164, 106, 165, 105,  84, 237,  54,  69,
     94,  92, 106, 152, 120, 142, 249, 156,
     21, 141, 229, 187, 241,  24, 201, 176,
     35
  ]
  []
  key ECPair {
    __D: <Buffer f0 a5 4c 6d dd 1d d5 e7 8b 8a b2 8c a1 57 20 65 ac 1f c2 a4 72 ba 1f 60 41 e2 08 0d e1 40 a3 45>,
    __Q: undefined,
    compressed: true,
    network: {
      messagePrefix: '\x18Bitcoin Signed Message:\n',
      bech32: 'tb',
      bip32: { public: 70617039, private: 70615956 },
      pubKeyHash: 111,
      scriptHash: 196,
      wif: 239
    },
    lowR: false
  }
  key pub Uint8Array(33) [
      2, 248,  59,  32, 158, 235,  60, 129,
    164, 106, 165, 105,  84, 237,  54,  69,
     94,  92, 106, 152, 120, 142, 249, 156,
     21, 141, 229, 187, 241,  24, 201, 176,
     35
  ]
  Private Key (WIF): cVeV7EtdSB2waytpSAikiuXakmWvmaaAnyw1X9cxrokKEdWgWuxz
  Testnet Address: tb1plqajp8ht8jq6g649d92w6dj9tewx4xrc3muec9vdukalzxxfkq3s2vk3nu

  //funded with TxID 62d9b44b6a6268bd4a74ab2141133343849f012b694e0ff7c32b0b3f5e3c87fa
  */