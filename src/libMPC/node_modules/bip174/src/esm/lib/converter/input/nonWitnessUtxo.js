import { InputTypes } from '../../typeFields.js';
import * as tools from 'uint8array-tools';
export function decode(keyVal) {
  if (keyVal.key[0] !== InputTypes.NON_WITNESS_UTXO) {
    throw new Error(
      'Decode Error: could not decode nonWitnessUtxo with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  return keyVal.value;
}
export function encode(data) {
  return {
    key: new Uint8Array([InputTypes.NON_WITNESS_UTXO]),
    value: data,
  };
}
export const expected = 'Uint8Array';
export function check(data) {
  return data instanceof Uint8Array;
}
export function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.nonWitnessUtxo === undefined;
}
