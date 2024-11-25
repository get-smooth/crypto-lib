import { InputTypes } from '../../typeFields.js';
import * as tools from 'uint8array-tools';
export function decode(keyVal) {
  if (keyVal.key[0] !== InputTypes.TAP_MERKLE_ROOT || keyVal.key.length !== 1) {
    throw new Error(
      'Decode Error: could not decode tapMerkleRoot with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  if (!check(keyVal.value)) {
    throw new Error('Decode Error: tapMerkleRoot not a 32-byte hash');
  }
  return keyVal.value;
}
export function encode(value) {
  const key = Uint8Array.from([InputTypes.TAP_MERKLE_ROOT]);
  return { key, value };
}
export const expected = 'Uint8Array';
export function check(data) {
  return data instanceof Uint8Array && data.length === 32;
}
export function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.tapMerkleRoot === undefined;
}
