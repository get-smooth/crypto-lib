import { InputTypes } from '../../typeFields.js';
import * as tools from 'uint8array-tools';
import * as varuint from 'varuint-bitcoin';
export function decode(keyVal) {
  if (keyVal.key[0] !== InputTypes.WITNESS_UTXO) {
    throw new Error(
      'Decode Error: could not decode witnessUtxo with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  const value = tools.readInt64(keyVal.value, 0, 'LE');
  let _offset = 8;
  const { numberValue: scriptLen, bytes } = varuint.decode(
    keyVal.value,
    _offset,
  );
  _offset += bytes;
  const script = keyVal.value.slice(_offset);
  if (script.length !== scriptLen) {
    throw new Error('Decode Error: WITNESS_UTXO script is not proper length');
  }
  return {
    script,
    value,
  };
}
export function encode(data) {
  const { script, value } = data;
  const varuintlen = varuint.encodingLength(script.length);
  const result = new Uint8Array(8 + varuintlen + script.length);
  tools.writeInt64(result, 0, BigInt(value), 'LE');
  varuint.encode(script.length, result, 8);
  result.set(script, 8 + varuintlen);
  return {
    key: Uint8Array.from([InputTypes.WITNESS_UTXO]),
    value: result,
  };
}
export const expected = '{ script: Uint8Array; value: bigint; }';
export function check(data) {
  return data.script instanceof Uint8Array && typeof data.value === 'bigint';
}
export function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.witnessUtxo === undefined;
}
