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
const range = n => [...Array(n).keys()];
function decode(keyVal) {
  if (keyVal.key[0] !== typeFields_js_1.GlobalTypes.GLOBAL_XPUB) {
    throw new Error(
      'Decode Error: could not decode globalXpub with key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  if (keyVal.key.length !== 79 || ![2, 3].includes(keyVal.key[46])) {
    throw new Error(
      'Decode Error: globalXpub has invalid extended pubkey in key 0x' +
        tools.toHex(keyVal.key),
    );
  }
  if ((keyVal.value.length / 4) % 1 !== 0) {
    throw new Error(
      'Decode Error: Global GLOBAL_XPUB value length should be multiple of 4',
    );
  }
  const extendedPubkey = keyVal.key.slice(1);
  const data = {
    masterFingerprint: keyVal.value.slice(0, 4),
    extendedPubkey,
    path: 'm',
  };
  for (const i of range(keyVal.value.length / 4 - 1)) {
    const val = tools.readUInt32(keyVal.value, i * 4 + 4, 'LE');
    const isHard = !!(val & 0x80000000);
    const idx = val & 0x7fffffff;
    data.path += '/' + idx.toString(10) + (isHard ? "'" : '');
  }
  return data;
}
exports.decode = decode;
function encode(data) {
  const head = new Uint8Array([typeFields_js_1.GlobalTypes.GLOBAL_XPUB]);
  const key = tools.concat([head, data.extendedPubkey]);
  const splitPath = data.path.split('/');
  const value = new Uint8Array(splitPath.length * 4);
  value.set(data.masterFingerprint, 0);
  let offset = 4;
  splitPath.slice(1).forEach(level => {
    const isHard = level.slice(-1) === "'";
    let num = 0x7fffffff & parseInt(isHard ? level.slice(0, -1) : level, 10);
    if (isHard) num += 0x80000000;
    tools.writeUInt32(value, offset, num, 'LE');
    offset += 4;
  });
  return {
    key,
    value,
  };
}
exports.encode = encode;
exports.expected =
  '{ masterFingerprint: Uint8Array; extendedPubkey: Uint8Array; path: string; }';
function check(data) {
  const epk = data.extendedPubkey;
  const mfp = data.masterFingerprint;
  const p = data.path;
  return (
    epk instanceof Uint8Array &&
    epk.length === 78 &&
    [2, 3].indexOf(epk[45]) > -1 &&
    mfp instanceof Uint8Array &&
    mfp.length === 4 &&
    typeof p === 'string' &&
    !!p.match(/^m(\/\d+'?)*$/)
  );
}
exports.check = check;
function canAddToArray(array, item, dupeSet) {
  const dupeString = tools.toHex(item.extendedPubkey);
  if (dupeSet.has(dupeString)) return false;
  dupeSet.add(dupeString);
  return (
    array.filter(v => tools.compare(v.extendedPubkey, item.extendedPubkey))
      .length === 0
  );
}
exports.canAddToArray = canAddToArray;
