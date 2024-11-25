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
  if (keyVal.key[0] !== typeFields_js_1.InputTypes.TAP_LEAF_SCRIPT) {
    throw new Error(
      'Decode Error: could not decode tapLeafScript with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  if ((keyVal.key.length - 2) % 32 !== 0) {
    throw new Error(
      'Decode Error: tapLeafScript has invalid control block in key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  const leafVersion = keyVal.value[keyVal.value.length - 1];
  if ((keyVal.key[1] & 0xfe) !== leafVersion) {
    throw new Error(
      'Decode Error: tapLeafScript bad leaf version in key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  const script = keyVal.value.slice(0, -1);
  const controlBlock = keyVal.key.slice(1);
  return { controlBlock, script, leafVersion };
}
exports.decode = decode;
function encode(tScript) {
  const head = Uint8Array.from([typeFields_js_1.InputTypes.TAP_LEAF_SCRIPT]);
  const verBuf = Uint8Array.from([tScript.leafVersion]);
  return {
    key: tools.concat([head, tScript.controlBlock]),
    value: tools.concat([tScript.script, verBuf]),
  };
}
exports.encode = encode;
exports.expected =
  '{ controlBlock: Uint8Array; leafVersion: number, script: Uint8Array; }';
function check(data) {
  return (
    data.controlBlock instanceof Uint8Array &&
    (data.controlBlock.length - 1) % 32 === 0 &&
    (data.controlBlock[0] & 0xfe) === data.leafVersion &&
    data.script instanceof Uint8Array
  );
}
exports.check = check;
function canAddToArray(array, item, dupeSet) {
  const dupeString = tools.toHex(item.controlBlock);
  if (dupeSet.has(dupeString)) return false;
  dupeSet.add(dupeString);
  return (
    array.filter(v => tools.compare(v.controlBlock, item.controlBlock) === 0)
      .length === 0
  );
}
exports.canAddToArray = canAddToArray;
