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
    if (keyVal.key[0] !== TYPE_BYTE || keyVal.key.length !== 1) {
      throw new Error(
        'Decode Error: could not decode tapInternalKey with key 0x' +
          tools.toHex(keyVal.key),
      );
    }
    if (keyVal.value.length !== 32) {
      throw new Error(
        'Decode Error: tapInternalKey not a 32-byte x-only pubkey',
      );
    }
    return keyVal.value;
  }
  function encode(value) {
    const key = Uint8Array.from([TYPE_BYTE]);
    return { key, value };
  }
  const expected = 'Uint8Array';
  function check(data) {
    return data instanceof Uint8Array && data.length === 32;
  }
  function canAdd(currentData, newData) {
    return (
      !!currentData && !!newData && currentData.tapInternalKey === undefined
    );
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
