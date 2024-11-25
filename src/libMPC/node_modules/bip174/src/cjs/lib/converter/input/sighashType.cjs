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
  if (keyVal.key[0] !== typeFields_js_1.InputTypes.SIGHASH_TYPE) {
    throw new Error(
      'Decode Error: could not decode sighashType with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  return Number(tools.readUInt32(keyVal.value, 0, 'LE'));
}
exports.decode = decode;
function encode(data) {
  const key = Uint8Array.from([typeFields_js_1.InputTypes.SIGHASH_TYPE]);
  const value = new Uint8Array(4);
  tools.writeUInt32(value, 0, data, 'LE');
  return {
    key,
    value,
  };
}
exports.encode = encode;
exports.expected = 'number';
function check(data) {
  return typeof data === 'number';
}
exports.check = check;
function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.sighashType === undefined;
}
exports.canAdd = canAdd;
