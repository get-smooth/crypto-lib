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
const index_js_1 = require('./combiner/index.cjs');
const index_js_2 = require('./parser/index.cjs');
const typeFields_js_1 = require('./typeFields.cjs');
const utils_js_1 = require('./utils.cjs');
const tools = __importStar(require('uint8array-tools'));
class Psbt {
  constructor(tx) {
    this.inputs = [];
    this.outputs = [];
    this.globalMap = {
      unsignedTx: tx,
    };
  }
  static fromBase64(data, txFromBuffer) {
    const buffer = tools.fromBase64(data);
    return this.fromBuffer(buffer, txFromBuffer);
  }
  static fromHex(data, txFromBuffer) {
    const buffer = tools.fromHex(data);
    return this.fromBuffer(buffer, txFromBuffer);
  }
  static fromBuffer(buffer, txFromBuffer) {
    const results = index_js_2.psbtFromBuffer(buffer, txFromBuffer);
    const psbt = new this(results.globalMap.unsignedTx);
    Object.assign(psbt, results);
    return psbt;
  }
  toBase64() {
    const buffer = this.toBuffer();
    return tools.toBase64(buffer);
  }
  toHex() {
    const buffer = this.toBuffer();
    return tools.toHex(buffer);
  }
  toBuffer() {
    return index_js_2.psbtToBuffer(this);
  }
  updateGlobal(updateData) {
    utils_js_1.updateGlobal(updateData, this.globalMap);
    return this;
  }
  updateInput(inputIndex, updateData) {
    const input = utils_js_1.checkForInput(this.inputs, inputIndex);
    utils_js_1.updateInput(updateData, input);
    return this;
  }
  updateOutput(outputIndex, updateData) {
    const output = utils_js_1.checkForOutput(this.outputs, outputIndex);
    utils_js_1.updateOutput(updateData, output);
    return this;
  }
  addUnknownKeyValToGlobal(keyVal) {
    utils_js_1.checkHasKey(
      keyVal,
      this.globalMap.unknownKeyVals,
      utils_js_1.getEnumLength(typeFields_js_1.GlobalTypes),
    );
    if (!this.globalMap.unknownKeyVals) this.globalMap.unknownKeyVals = [];
    this.globalMap.unknownKeyVals.push(keyVal);
    return this;
  }
  addUnknownKeyValToInput(inputIndex, keyVal) {
    const input = utils_js_1.checkForInput(this.inputs, inputIndex);
    utils_js_1.checkHasKey(
      keyVal,
      input.unknownKeyVals,
      utils_js_1.getEnumLength(typeFields_js_1.InputTypes),
    );
    if (!input.unknownKeyVals) input.unknownKeyVals = [];
    input.unknownKeyVals.push(keyVal);
    return this;
  }
  addUnknownKeyValToOutput(outputIndex, keyVal) {
    const output = utils_js_1.checkForOutput(this.outputs, outputIndex);
    utils_js_1.checkHasKey(
      keyVal,
      output.unknownKeyVals,
      utils_js_1.getEnumLength(typeFields_js_1.OutputTypes),
    );
    if (!output.unknownKeyVals) output.unknownKeyVals = [];
    output.unknownKeyVals.push(keyVal);
    return this;
  }
  addInput(inputData) {
    this.globalMap.unsignedTx.addInput(inputData);
    this.inputs.push({
      unknownKeyVals: [],
    });
    const addKeyVals = inputData.unknownKeyVals || [];
    const inputIndex = this.inputs.length - 1;
    if (!Array.isArray(addKeyVals)) {
      throw new Error('unknownKeyVals must be an Array');
    }
    addKeyVals.forEach(keyVal =>
      this.addUnknownKeyValToInput(inputIndex, keyVal),
    );
    utils_js_1.addInputAttributes(this.inputs, inputData);
    return this;
  }
  addOutput(outputData) {
    this.globalMap.unsignedTx.addOutput(outputData);
    this.outputs.push({
      unknownKeyVals: [],
    });
    const addKeyVals = outputData.unknownKeyVals || [];
    const outputIndex = this.outputs.length - 1;
    if (!Array.isArray(addKeyVals)) {
      throw new Error('unknownKeyVals must be an Array');
    }
    addKeyVals.forEach(keyVal =>
      this.addUnknownKeyValToOutput(outputIndex, keyVal),
    );
    utils_js_1.addOutputAttributes(this.outputs, outputData);
    return this;
  }
  clearFinalizedInput(inputIndex) {
    const input = utils_js_1.checkForInput(this.inputs, inputIndex);
    utils_js_1.inputCheckUncleanFinalized(inputIndex, input);
    for (const key of Object.keys(input)) {
      if (
        ![
          'witnessUtxo',
          'nonWitnessUtxo',
          'finalScriptSig',
          'finalScriptWitness',
          'unknownKeyVals',
        ].includes(key)
      ) {
        // @ts-ignore
        delete input[key];
      }
    }
    return this;
  }
  combine(...those) {
    // Combine this with those.
    // Return self for chaining.
    const result = index_js_1.combine([this].concat(those));
    Object.assign(this, result);
    return this;
  }
  getTransaction() {
    return this.globalMap.unsignedTx.toBuffer();
  }
}
exports.Psbt = Psbt;
var utils_js_2 = require('./utils.cjs');
exports.checkForInput = utils_js_2.checkForInput;
exports.checkForOutput = utils_js_2.checkForOutput;
