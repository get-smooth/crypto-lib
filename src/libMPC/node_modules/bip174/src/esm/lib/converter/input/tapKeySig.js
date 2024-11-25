import { InputTypes } from '../../typeFields.js';
import * as tools from 'uint8array-tools';
export function decode(keyVal) {
  if (keyVal.key[0] !== InputTypes.TAP_KEY_SIG || keyVal.key.length !== 1) {
    throw new Error(
      'Decode Error: could not decode tapKeySig with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  if (!check(keyVal.value)) {
    throw new Error(
      'Decode Error: tapKeySig not a valid 64-65-byte BIP340 signature',
    );
  }
  return keyVal.value;
}
export function encode(value) {
  const key = Uint8Array.from([InputTypes.TAP_KEY_SIG]);
  return { key, value };
}
export const expected = 'Uint8Array';
export function check(data) {
  return (
    data instanceof Uint8Array && (data.length === 64 || data.length === 65)
  );
}
export function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.tapKeySig === undefined;
}
