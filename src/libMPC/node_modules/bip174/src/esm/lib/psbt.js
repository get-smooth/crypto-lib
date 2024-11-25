import { combine } from './combiner/index.js';
import { psbtFromBuffer, psbtToBuffer } from './parser/index.js';
import { GlobalTypes, InputTypes, OutputTypes } from './typeFields.js';
import {
  addInputAttributes,
  addOutputAttributes,
  checkForInput,
  checkForOutput,
  checkHasKey,
  getEnumLength,
  inputCheckUncleanFinalized,
  updateGlobal,
  updateInput,
  updateOutput,
} from './utils.js';
import * as tools from 'uint8array-tools';
export class Psbt {
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
    const results = psbtFromBuffer(buffer, txFromBuffer);
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
    return psbtToBuffer(this);
  }
  updateGlobal(updateData) {
    updateGlobal(updateData, this.globalMap);
    return this;
  }
  updateInput(inputIndex, updateData) {
    const input = checkForInput(this.inputs, inputIndex);
    updateInput(updateData, input);
    return this;
  }
  updateOutput(outputIndex, updateData) {
    const output = checkForOutput(this.outputs, outputIndex);
    updateOutput(updateData, output);
    return this;
  }
  addUnknownKeyValToGlobal(keyVal) {
    checkHasKey(
      keyVal,
      this.globalMap.unknownKeyVals,
      getEnumLength(GlobalTypes),
    );
    if (!this.globalMap.unknownKeyVals) this.globalMap.unknownKeyVals = [];
    this.globalMap.unknownKeyVals.push(keyVal);
    return this;
  }
  addUnknownKeyValToInput(inputIndex, keyVal) {
    const input = checkForInput(this.inputs, inputIndex);
    checkHasKey(keyVal, input.unknownKeyVals, getEnumLength(InputTypes));
    if (!input.unknownKeyVals) input.unknownKeyVals = [];
    input.unknownKeyVals.push(keyVal);
    return this;
  }
  addUnknownKeyValToOutput(outputIndex, keyVal) {
    const output = checkForOutput(this.outputs, outputIndex);
    checkHasKey(keyVal, output.unknownKeyVals, getEnumLength(OutputTypes));
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
    addInputAttributes(this.inputs, inputData);
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
    addOutputAttributes(this.outputs, outputData);
    return this;
  }
  clearFinalizedInput(inputIndex) {
    const input = checkForInput(this.inputs, inputIndex);
    inputCheckUncleanFinalized(inputIndex, input);
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
    const result = combine([this].concat(those));
    Object.assign(this, result);
    return this;
  }
  getTransaction() {
    return this.globalMap.unsignedTx.toBuffer();
  }
}
export { checkForInput, checkForOutput } from './utils.js';
