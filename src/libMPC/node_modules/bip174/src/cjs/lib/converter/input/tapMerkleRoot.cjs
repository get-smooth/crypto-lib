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
function decode(keyVal) {
  if (
    keyVal.key[0] !== typeFields_js_1.InputTypes.TAP_MERKLE_ROOT ||
    keyVal.key.length !== 1
  ) {
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
exports.decode = decode;
function encode(value) {
  const key = Uint8Array.from([typeFields_js_1.InputTypes.TAP_MERKLE_ROOT]);
  return { key, value };
}
exports.encode = encode;
exports.expected = 'Uint8Array';
function check(data) {
  return data instanceof Uint8Array && data.length === 32;
}
exports.check = check;
function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.tapMerkleRoot === undefined;
}
exports.canAdd = canAdd;
