import { InputTypes } from '../../typeFields.js';
import * as tools from 'uint8array-tools';
export function decode(keyVal) {
  if (keyVal.key[0] !== InputTypes.PARTIAL_SIG) {
    throw new Error(
      'Decode Error: could not decode partialSig with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  if (
    !(keyVal.key.length === 34 || keyVal.key.length === 66) ||
    ![2, 3, 4].includes(keyVal.key[1])
  ) {
    throw new Error(
      'Decode Error: partialSig has invalid pubkey in key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  const pubkey = keyVal.key.slice(1);
  return {
    pubkey,
    signature: keyVal.value,
  };
}
export function encode(pSig) {
  const head = new Uint8Array([InputTypes.PARTIAL_SIG]);
  return {
    key: tools.concat([head, pSig.pubkey]),
    value: pSig.signature,
  };
}
export const expected = '{ pubkey: Uint8Array; signature: Uint8Array; }';
export function check(data) {
  return (
    data.pubkey instanceof Uint8Array &&
    data.signature instanceof Uint8Array &&
    [33, 65].includes(data.pubkey.length) &&
    [2, 3, 4].includes(data.pubkey[0]) &&
    isDerSigWithSighash(data.signature)
  );
}
function isDerSigWithSighash(buf) {
  if (!(buf instanceof Uint8Array) || buf.length < 9) return false;
  if (buf[0] !== 0x30) return false;
  if (buf.length !== buf[1] + 3) return false;
  if (buf[2] !== 0x02) return false;
  const rLen = buf[3];
  if (rLen > 33 || rLen < 1) return false;
  if (buf[3 + rLen + 1] !== 0x02) return false;
  const sLen = buf[3 + rLen + 2];
  if (sLen > 33 || sLen < 1) return false;
  if (buf.length !== 3 + rLen + 2 + sLen + 2) return false;
  return true;
}
export function canAddToArray(array, item, dupeSet) {
  const dupeString = tools.toHex(item.pubkey);
  if (dupeSet.has(dupeString)) return false;
  dupeSet.add(dupeString);
  return (
    array.filter(v => tools.compare(v.pubkey, item.pubkey) === 0).length === 0
  );
}
