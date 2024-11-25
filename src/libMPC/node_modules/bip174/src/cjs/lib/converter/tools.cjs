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
const varuint = __importStar(require('varuint-bitcoin'));
const tools = __importStar(require('uint8array-tools'));
exports.range = n => [...Array(n).keys()];
function reverseBuffer(buffer) {
  if (buffer.length < 1) return buffer;
  let j = buffer.length - 1;
  let tmp = 0;
  for (let i = 0; i < buffer.length / 2; i++) {
    tmp = buffer[i];
    buffer[i] = buffer[j];
    buffer[j] = tmp;
    j--;
  }
  return buffer;
}
exports.reverseBuffer = reverseBuffer;
function keyValsToBuffer(keyVals) {
  const buffers = keyVals.map(keyValToBuffer);
  buffers.push(Uint8Array.from([0]));
  return tools.concat(buffers);
}
exports.keyValsToBuffer = keyValsToBuffer;
function keyValToBuffer(keyVal) {
  const keyLen = keyVal.key.length;
  const valLen = keyVal.value.length;
  const keyVarIntLen = varuint.encodingLength(keyLen);
  const valVarIntLen = varuint.encodingLength(valLen);
  const buffer = new Uint8Array(keyVarIntLen + keyLen + valVarIntLen + valLen);
  varuint.encode(keyLen, buffer, 0);
  buffer.set(keyVal.key, keyVarIntLen);
  varuint.encode(valLen, buffer, keyVarIntLen + keyLen);
  buffer.set(keyVal.value, keyVarIntLen + keyLen + valVarIntLen);
  return buffer;
}
exports.keyValToBuffer = keyValToBuffer;
