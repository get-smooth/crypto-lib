import * as varuint from 'varuint-bitcoin';
import * as tools from 'uint8array-tools';
import * as bip32Derivation from './bip32Derivation.js';
const isValidBIP340Key = pubkey => pubkey.length === 32;
export function makeConverter(TYPE_BYTE) {
  const parent = bip32Derivation.makeConverter(TYPE_BYTE, isValidBIP340Key);
  function decode(keyVal) {
    const { numberValue: nHashes, bytes: nHashesLen } = varuint.decode(
      keyVal.value,
    );
    const base = parent.decode({
      key: keyVal.key,
      value: keyVal.value.slice(nHashesLen + Number(nHashes) * 32),
    });
    const leafHashes = new Array(Number(nHashes));
    for (let i = 0, _offset = nHashesLen; i < nHashes; i++, _offset += 32) {
      leafHashes[i] = keyVal.value.slice(_offset, _offset + 32);
    }
    return { ...base, leafHashes };
  }
  function encode(data) {
    const base = parent.encode(data);
    const nHashesLen = varuint.encodingLength(data.leafHashes.length);
    const nHashesBuf = new Uint8Array(nHashesLen);
    varuint.encode(data.leafHashes.length, nHashesBuf);
    const value = tools.concat([nHashesBuf, ...data.leafHashes, base.value]);
    return { ...base, value };
  }
  const expected =
    '{ ' +
    'masterFingerprint: Uint8Array; ' +
    'pubkey: Uint8Array; ' +
    'path: string; ' +
    'leafHashes: Uint8Array[]; ' +
    '}';
  function check(data) {
    return (
      Array.isArray(data.leafHashes) &&
      data.leafHashes.every(
        leafHash => leafHash instanceof Uint8Array && leafHash.length === 32,
      ) &&
      parent.check(data)
    );
  }
  return {
    decode,
    encode,
    check,
    expected,
    canAddToArray: parent.canAddToArray,
  };
}
