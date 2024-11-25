# ecpair
[![Github CI](https://github.com/bitcoinjs/ecpair/actions/workflows/main_ci.yml/badge.svg)](https://github.com/bitcoinjs/ecpair/actions/workflows/main_ci.yml) [![NPM](https://img.shields.io/npm/v/ecpair.svg)](https://www.npmjs.org/package/ecpair) [![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat-square)](https://github.com/prettier/prettier)

A library for managing SECP256k1 keypairs written in TypeScript with transpiled JavaScript committed to git.

## Example

TypeScript

``` typescript
import { Signer, SignerAsync, ECPairInterface, ECPairFactory, ECPairAPI, TinySecp256k1Interface } from 'ecpair';
import * as crypto from 'crypto';

// You need to provide the ECC library. The ECC library must implement 
// all the methods of the `TinySecp256k1Interface` interface.
const tinysecp: TinySecp256k1Interface = require('tiny-secp256k1');
const ECPair: ECPairAPI = ECPairFactory(tinysecp);

// You don't need to explicitly write ECPairInterface, but just to show
// that the keyPair implements the interface this example includes it.

// From WIF
const keyPair1: ECPairInterface = ECPair.fromWIF('KynD8ZKdViVo5W82oyxvE18BbG6nZPVQ8Td8hYbwU94RmyUALUik');
// Random private key
const keyPair2 = ECPair.fromPrivateKey(crypto.randomBytes(32));
// OR (uses randombytes library, compatible with browser)
const keyPair3 = ECPair.makeRandom();
// OR use your own custom random buffer generator BE CAREFUL!!!!
const customRandomBufferFunc = (size: number): Buffer => crypto.randomBytes(size);
const keyPair4 = ECPair.makeRandom({ rng: customRandomBufferFunc });
// From pubkey (33 or 65 byte DER format public key)
const keyPair5 = ECPair.fromPublicKey(keyPair1.publicKey);

// Pass a custom network
const network = {}; // Your custom network object here
ECPair.makeRandom({ network });
ECPair.fromPrivateKey(crypto.randomBytes(32), { network });
ECPair.fromPublicKey(keyPair1.publicKey, { network });
// fromWIF will check the WIF version against the network you pass in
// pass in multiple networks if you are not sure
ECPair.fromWIF('wif key...', network);
const network2 = {}; // Your custom network object here
const network3 = {}; // Your custom network object here
ECPair.fromWIF('wif key...', [network, network2, network3]);
```

## LICENSE [MIT](LICENSE)
Written and tested by [bitcoinjs-lib](https://github.com/bitcoinjs/bitcoinjs-lib) contributors since 2014.
