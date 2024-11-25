import { InputTypes } from '../../typeFields.js';
import * as tools from 'uint8array-tools';
export function decode(keyVal) {
  if (keyVal.key[0] !== InputTypes.FINAL_SCRIPTWITNESS) {
    throw new Error(
      'Decode Error: could not decode finalScriptWitness with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  return keyVal.value;
}
export function encode(data) {
  const key = new Uint8Array([InputTypes.FINAL_SCRIPTWITNESS]);
  return {
    key,
    value: data,
  };
}
export const expected = 'Uint8Array';
export function check(data) {
  return data instanceof Uint8Array;
}
export function canAdd(currentData, newData) {
  return (
    !!currentData && !!newData && currentData.finalScriptWitness === undefined
  );
}
