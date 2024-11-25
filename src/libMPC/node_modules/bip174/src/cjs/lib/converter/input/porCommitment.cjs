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
  if (keyVal.key[0] !== typeFields_js_1.InputTypes.POR_COMMITMENT) {
    throw new Error(
      'Decode Error: could not decode porCommitment with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  return tools.toUtf8(keyVal.value);
}
exports.decode = decode;
function encode(data) {
  const key = new Uint8Array([typeFields_js_1.InputTypes.POR_COMMITMENT]);
  return {
    key,
    value: tools.fromUtf8(data),
  };
}
exports.encode = encode;
exports.expected = 'string';
function check(data) {
  return typeof data === 'string';
}
exports.check = check;
function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.porCommitment === undefined;
}
exports.canAdd = canAdd;
