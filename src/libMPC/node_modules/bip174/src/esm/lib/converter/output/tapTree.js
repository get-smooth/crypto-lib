import { OutputTypes } from '../../typeFields.js';
import * as varuint from 'varuint-bitcoin';
import * as tools from 'uint8array-tools';
export function decode(keyVal) {
  if (keyVal.key[0] !== OutputTypes.TAP_TREE || keyVal.key.length !== 1) {
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
export function encode(tree) {
  const key = Uint8Array.from([OutputTypes.TAP_TREE]);
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
export const expected =
  '{ leaves: [{ depth: number; leafVersion: number, script: Uint8Array; }] }';
export function check(data) {
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
export function canAdd(currentData, newData) {
  return !!currentData && !!newData && currentData.tapTree === undefined;
}
