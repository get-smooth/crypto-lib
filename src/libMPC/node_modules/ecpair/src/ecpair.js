'use strict';
Object.defineProperty(exports, '__esModule', { value: true });
exports.ECPairFactory = exports.networks = void 0;
const networks = require('./networks');
exports.networks = networks;
const types = require('./types');
const randomBytes = require('randombytes');
const wif = require('wif');
const testecc_1 = require('./testecc');
const isOptions = types.typeforce.maybe(
  types.typeforce.compile({
    compressed: types.maybe(types.Boolean),
    network: types.maybe(types.Network),
  }),
);
function ECPairFactory(ecc) {
  (0, testecc_1.testEcc)(ecc);
  function isPoint(maybePoint) {
    return ecc.isPoint(maybePoint);
  }
  function fromPrivateKey(buffer, options) {
    types.typeforce(types.Buffer256bit, buffer);
    if (!ecc.isPrivate(buffer))
      throw new TypeError('Private key not in range [1, n)');
    types.typeforce(isOptions, options);
    return new ECPair(buffer, undefined, options);
  }
  function fromPublicKey(buffer, options) {
    types.typeforce(ecc.isPoint, buffer);
    types.typeforce(isOptions, options);
    return new ECPair(undefined, buffer, options);
  }
  function fromWIF(wifString, network) {
    const decoded = wif.decode(wifString);
    const version = decoded.version;
    // list of networks?
    if (types.Array(network)) {
      network = network
        .filter((x) => {
          return version === x.wif;
        })
        .pop();
      if (!network) throw new Error('Unknown network version');
      // otherwise, assume a network object (or default to bitcoin)
    } else {
      network = network || networks.bitcoin;
      if (version !== network.wif) throw new Error('Invalid network version');
    }
    return fromPrivateKey(decoded.privateKey, {
      compressed: decoded.compressed,
      network: network,
    });
  }
  function makeRandom(options) {
    types.typeforce(isOptions, options);
    if (options === undefined) options = {};
    const rng = options.rng || randomBytes;
    let d;
    do {
      d = rng(32);
      types.typeforce(types.Buffer256bit, d);
    } while (!ecc.isPrivate(d));
    return fromPrivateKey(d, options);
  }
  class ECPair {
    __D;
    __Q;
    compressed;
    network;
    lowR;
    constructor(__D, __Q, options) {
      this.__D = __D;
      this.__Q = __Q;
      this.lowR = false;
      if (options === undefined) options = {};
      this.compressed =
        options.compressed === undefined ? true : options.compressed;
      this.network = options.network || networks.bitcoin;
      if (__Q !== undefined)
        this.__Q = Buffer.from(ecc.pointCompress(__Q, this.compressed));
    }
    get privateKey() {
      return this.__D;
    }
    get publicKey() {
      if (!this.__Q)
        this.__Q = Buffer.from(ecc.pointFromScalar(this.__D, this.compressed));
      return this.__Q;
    }
    toWIF() {
      if (!this.__D) throw new Error('Missing private key');
      return wif.encode(this.network.wif, this.__D, this.compressed);
    }
    sign(hash, lowR) {
      if (!this.__D) throw new Error('Missing private key');
      if (lowR === undefined) lowR = this.lowR;
      if (lowR === false) {
        return Buffer.from(ecc.sign(hash, this.__D));
      } else {
        let sig = ecc.sign(hash, this.__D);
        const extraData = Buffer.alloc(32, 0);
        let counter = 0;
        // if first try is lowR, skip the loop
        // for second try and on, add extra entropy counting up
        while (sig[0] > 0x7f) {
          counter++;
          extraData.writeUIntLE(counter, 0, 6);
          sig = ecc.sign(hash, this.__D, extraData);
        }
        return Buffer.from(sig);
      }
    }
    signSchnorr(hash) {
      if (!this.privateKey) throw new Error('Missing private key');
      if (!ecc.signSchnorr)
        throw new Error('signSchnorr not supported by ecc library');
      return Buffer.from(ecc.signSchnorr(hash, this.privateKey));
    }
    verify(hash, signature) {
      return ecc.verify(hash, this.publicKey, signature);
    }
    verifySchnorr(hash, signature) {
      if (!ecc.verifySchnorr)
        throw new Error('verifySchnorr not supported by ecc library');
      return ecc.verifySchnorr(hash, this.publicKey.subarray(1, 33), signature);
    }
  }
  return {
    isPoint,
    fromPrivateKey,
    fromPublicKey,
    fromWIF,
    makeRandom,
  };
}
exports.ECPairFactory = ECPairFactory;
