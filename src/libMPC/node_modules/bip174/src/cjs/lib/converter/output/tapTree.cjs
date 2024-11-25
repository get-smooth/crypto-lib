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
const varuint = __importStar(require('varuint-bitcoin'));
const tools = __importStar(require('uint8array-tools'));
function decode(keyVal) {
  if (
    keyVal.key[0] !== typeFields_js_1.OutputTypes.TAP_TREE ||
    keyVal.key.length !== 1
  ) {
    throw new Error(
      'Decode Error: could not decode tapTree with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  let _offset = 0;
  const data = [];
  while (_offset < keyVal.value.length) {
    const depth = keyVal.value[_offset++];
    const leafVersion = keyVal.value[_offset++];
    const { numberValue: scriptLen, bytes } = varuint.decode(
      keyVal.value,
      _offset,
    );
    _offset += bytes;
    data.push({
      depth,
      leafVersion,
      script: keyVal.value.slice(_offset, _offset + scriptLen),
    });
    _offset += scriptLen;
  }
  return { leaves: data };
}
exports.decode = decode;
function encode(tree) {
  const key = Uint8Array.from([typeFields_js_1.OutputTypes.TAP_TREE]);
  const bufs = [].concat(
    ...tree.leaves.map(tapLeaf => [
      Uint8Array.of(tapLeaf.depth, tapLeaf.leafVersion),
      varuint.encode(BigInt(tapLeaf.script.length)).buffer,
      tapLeaf.script,
    ]),
  );
  return {
    key,
    value: tools.concat(bufs),
  };
}
exports.encode = encode;
exports.expected =
  '{ leaves: [{ depth: number; leafVersion: number, script: Uint8Array; }] }';
function check(data) {
  return (
    Array.isArray(data.leaves) &&
    data.leaves.every(
      tapLeaf =>
        tapLeaf.depth >= 0 &&
        tapLeaf.depth <= 128 &&
        (tapLeaf.leafVersion & 0xfe) === tapLeaf.leafVersion &&
        tapLeaf.script instanceof Uint8Array,
    )
  );
}
exports.check = check;
function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.tapTree === undefined;
}
exports.canAdd = canAdd;
