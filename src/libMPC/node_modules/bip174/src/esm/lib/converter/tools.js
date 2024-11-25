import * as varuint from 'varuint-bitcoin';
import * as tools from 'uint8array-tools';
export const range = n => [...Array(n).keys()];
export function reverseBuffer(buffer) {
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
export function keyValsToBuffer(keyVals) {
  const buffers = keyVals.map(keyValToBuffer);
  buffers.push(Uint8Array.from([0]));
  return tools.concat(buffers);
}
export function keyValToBuffer(keyVal) {
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
