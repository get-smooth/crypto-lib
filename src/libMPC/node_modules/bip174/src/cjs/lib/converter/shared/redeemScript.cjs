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
const tools = __importStar(require('uint8array-tools'));
function makeConverter(TYPE_BYTE) {
  function decode(keyVal) {
    if (keyVal.key[0] !== TYPE_BYTE) {
      throw new Error(
        'Decode Error: could not decode redeemScript with key 0x' +
          tools.toHex(keyVal.key),
      );
    }
    return keyVal.value;
  }
  function encode(data) {
    const key = Uint8Array.from([TYPE_BYTE]);
    return {
      key,
      value: data,
    };
  }
  const expected = 'Uint8Array';
  function check(data) {
    return data instanceof Uint8Array;
  }
  function canAdd(currentData, newData) {
    return !!currentData && !!newData && currentData.redeemScript === undefined;
  }
  return {
    decode,
    encode,
    check,
    expected,
    canAdd,
  };
}
exports.makeConverter = makeConverter;
