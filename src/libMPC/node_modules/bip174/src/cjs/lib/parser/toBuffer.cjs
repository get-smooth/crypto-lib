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
const convert = __importStar(require('../converter/index.cjs'));
const tools_js_1 = require('../converter/tools.cjs');
const tools = __importStar(require('uint8array-tools'));
function psbtToBuffer({ globalMap, inputs, outputs }) {
  const { globalKeyVals, inputKeyVals, outputKeyVals } = psbtToKeyVals({
    globalMap,
    inputs,
    outputs,
  });
  const globalBuffer = tools_js_1.keyValsToBuffer(globalKeyVals);
  const keyValsOrEmptyToBuffer = keyVals =>
    keyVals.length === 0
      ? [Uint8Array.from([0])]
      : keyVals.map(tools_js_1.keyValsToBuffer);
  const inputBuffers = keyValsOrEmptyToBuffer(inputKeyVals);
  const outputBuffers = keyValsOrEmptyToBuffer(outputKeyVals);
  const header = new Uint8Array(5);
  header.set([0x70, 0x73, 0x62, 0x74, 0xff], 0);
  return tools.concat(
    [header, globalBuffer].concat(inputBuffers, outputBuffers),
  );
}
exports.psbtToBuffer = psbtToBuffer;
const sortKeyVals = (a, b) => {
  return tools.compare(a.key, b.key);
};
function keyValsFromMap(keyValMap, converterFactory) {
  const keyHexSet = new Set();
  const keyVals = Object.entries(keyValMap).reduce((result, [key, value]) => {
    if (key === 'unknownKeyVals') return result;
    // We are checking for undefined anyways. So ignore TS error
    // @ts-ignore
    const converter = converterFactory[key];
    if (converter === undefined) return result;
    const encodedKeyVals = (Array.isArray(value) ? value : [value]).map(
      converter.encode,
    );
    const keyHexes = encodedKeyVals.map(kv => tools.toHex(kv.key));
    keyHexes.forEach(hex => {
      if (keyHexSet.has(hex))
        throw new Error('Serialize Error: Duplicate key: ' + hex);
      keyHexSet.add(hex);
    });
    return result.concat(encodedKeyVals);
  }, []);
  // Get other keyVals that have not yet been gotten
  const otherKeyVals = keyValMap.unknownKeyVals
    ? keyValMap.unknownKeyVals.filter(keyVal => {
        return !keyHexSet.has(tools.toHex(keyVal.key));
      })
    : [];
  return keyVals.concat(otherKeyVals).sort(sortKeyVals);
}
function psbtToKeyVals({ globalMap, inputs, outputs }) {
  // First parse the global keyVals
  // Get any extra keyvals to pass along
  return {
    globalKeyVals: keyValsFromMap(globalMap, convert.globals),
    inputKeyVals: inputs.map(i => keyValsFromMap(i, convert.inputs)),
    outputKeyVals: outputs.map(o => keyValsFromMap(o, convert.outputs)),
  };
}
exports.psbtToKeyVals = psbtToKeyVals;
