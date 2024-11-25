'use strict';
var __importStar =
  (this && this.__importStar) ||
  function(mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null)
      for (var k in mod)
        if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result['default'] = mod;
    return result;
  };
Object.defineProperty(exports, '__esModule', { value: true });
const typeFields_js_1 = require('../../typeFields.cjs');
const tools = __importStar(require('uint8array-tools'));
const varuint = __importStar(require('varuint-bitcoin'));
function decode(keyVal) {
  if (keyVal.key[0] !== typeFields_js_1.InputTypes.WITNESS_UTXO) {
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
exports.decode = decode;
function encode(data) {
  const { script, value } = data;
  const varuintlen = varuint.encodingLength(script.length);
  const result = new Uint8Array(8 + varuintlen + script.length);
  tools.writeInt64(result, 0, BigInt(value), 'LE');
  varuint.encode(script.length, result, 8);
  result.set(script, 8 + varuintlen);
  return {
    key: Uint8Array.from([typeFields_js_1.InputTypes.WITNESS_UTXO]),
    value: result,
  };
}
exports.encode = encode;
exports.expected = '{ script: Uint8Array; value: bigint; }';
function check(data) {
  return data.script instanceof Uint8Array && typeof data.value === 'bigint';
}
exports.check = check;
function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.witnessUtxo === undefined;
}
exports.canAdd = canAdd;
