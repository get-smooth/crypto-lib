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
  if (keyVal.key[0] !== typeFields_js_1.InputTypes.FINAL_SCRIPTWITNESS) {
    throw new Error(
      'Decode Error: could not decode finalScriptWitness with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  return keyVal.value;
}
exports.decode = decode;
function encode(data) {
  const key = new Uint8Array([typeFields_js_1.InputTypes.FINAL_SCRIPTWITNESS]);
  return {
    key,
    value: data,
  };
}
exports.encode = encode;
exports.expected = 'Uint8Array';
function check(data) {
  return data instanceof Uint8Array;
}
exports.check = check;
function canAdd(currentData, newData) {
  return (
    !!currentData && !!newData && currentData.finalScriptWitness === undefined
  );
}
exports.canAdd = canAdd;
