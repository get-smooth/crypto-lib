import { InputTypes } from '../../typeFields.js';
import * as tools from 'uint8array-tools';
export function decode(keyVal) {
  if (keyVal.key[0] !== InputTypes.POR_COMMITMENT) {
    throw new Error(
      'Decode Error: could not decode porCommitment with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  return tools.toUtf8(keyVal.value);
}
export function encode(data) {
  const key = new Uint8Array([InputTypes.POR_COMMITMENT]);
  return {
    key,
    value: tools.fromUtf8(data),
  };
}
export const expected = 'string';
export function check(data) {
  return typeof data === 'string';
}
export function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.porCommitment === undefined;
}
