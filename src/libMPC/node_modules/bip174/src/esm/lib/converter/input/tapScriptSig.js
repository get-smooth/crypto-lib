import { InputTypes } from '../../typeFields.js';
import * as tools from 'uint8array-tools';
export function decode(keyVal) {
  if (keyVal.key[0] !== InputTypes.TAP_SCRIPT_SIG) {
    throw new Error(
      'Decode Error: could not decode tapScriptSig with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  if (keyVal.key.length !== 65) {
    throw new Error(
      'Decode Error: tapScriptSig has invalid key 0x' + tools.toHex(keyVal.key),
    );
  }
  if (keyVal.value.length !== 64 && keyVal.value.length !== 65) {
    throw new Error(
      'Decode Error: tapScriptSig has invalid signature in key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  const pubkey = keyVal.key.slice(1, 33);
  const leafHash = keyVal.key.slice(33);
  return {
    pubkey,
    leafHash,
    signature: keyVal.value,
  };
}
export function encode(tSig) {
  const head = Uint8Array.from([InputTypes.TAP_SCRIPT_SIG]);
  return {
    key: tools.concat([head, tSig.pubkey, tSig.leafHash]),
    value: tSig.signature,
  };
}
export const expected =
  '{ pubkey: Uint8Array; leafHash: Uint8Array; signature: Uint8Array; }';
export function check(data) {
  return (
    data.pubkey instanceof Uint8Array &&
    data.leafHash instanceof Uint8Array &&
    data.signature instanceof Uint8Array &&
    data.pubkey.length === 32 &&
    data.leafHash.length === 32 &&
    (data.signature.length === 64 || data.signature.length === 65)
  );
}
export function canAddToArray(array, item, dupeSet) {
  const dupeString = tools.toHex(item.pubkey) + tools.toHex(item.leafHash);
  if (dupeSet.has(dupeString)) return false;
  dupeSet.add(dupeString);
  return (
    array.filter(
      v =>
        tools.compare(v.pubkey, item.pubkey) === 0 &&
        tools.compare(v.leafHash, item.leafHash) === 0,
    ).length === 0
  );
}
