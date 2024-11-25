import * as converter from './converter/index.js';
import * as tools from 'uint8array-tools';
export function checkForInput(inputs, inputIndex) {
  const input = inputs[inputIndex];
  if (input === undefined) throw new Error(`No input #${inputIndex}`);
  return input;
}
export function checkForOutput(outputs, outputIndex) {
  const output = outputs[outputIndex];
  if (output === undefined) throw new Error(`No output #${outputIndex}`);
  return output;
}
export function checkHasKey(checkKeyVal, keyVals, enumLength) {
  if (checkKeyVal.key[0] < enumLength) {
    throw new Error(
      `Use the method for your specific key instead of addUnknownKeyVal*`,
    );
  }
  if (
    keyVals &&
    keyVals.filter(kv => tools.compare(kv.key, checkKeyVal.key) === 0)
      .length !== 0
  ) {
    throw new Error(`Duplicate Key: ${tools.toHex(checkKeyVal.key)}`);
  }
}
export function getEnumLength(myenum) {
  let count = 0;
  Object.keys(myenum).forEach(val => {
    if (Number(isNaN(Number(val)))) {
      count++;
    }
  });
  return count;
}
export function inputCheckUncleanFinalized(inputIndex, input) {
  let result = false;
  if (input.nonWitnessUtxo || input.witnessUtxo) {
    const needScriptSig = !!input.redeemScript;
    const needWitnessScript = !!input.witnessScript;
    const scriptSigOK = !needScriptSig || !!input.finalScriptSig;
    const witnessScriptOK = !needWitnessScript || !!input.finalScriptWitness;
    const hasOneFinal = !!input.finalScriptSig || !!input.finalScriptWitness;
    result = scriptSigOK && witnessScriptOK && hasOneFinal;
  }
  if (result === false) {
    throw new Error(
      `Input #${inputIndex} has too much or too little data to clean`,
    );
  }
}
function throwForUpdateMaker(typeName, name, expected, data) {
  throw new Error(
    `Data for ${typeName} key ${name} is incorrect: Expected ` +
      `${expected} and got ${JSON.stringify(data)}`,
  );
}
function updateMaker(typeName) {
  return (updateData, mainData) => {
    // @ts-ignore
    for (const name of Object.keys(updateData)) {
      // @ts-ignore
      const data = updateData[name];
      // @ts-ignore
      const { canAdd, canAddToArray, check, expected } =
        // @ts-ignore
        converter[typeName + 's'][name] || {};
      const isArray = !!canAddToArray;
      // If unknown data. ignore and do not add
      if (check) {
        if (isArray) {
          if (
            !Array.isArray(data) ||
            // @ts-ignore
            (mainData[name] && !Array.isArray(mainData[name]))
          ) {
            throw new Error(`Key type ${name} must be an array`);
          }
          if (!data.every(check)) {
            throwForUpdateMaker(typeName, name, expected, data);
          }
          // @ts-ignore
          const arr = mainData[name] || [];
          const dupeCheckSet = new Set();
          if (!data.every(v => canAddToArray(arr, v, dupeCheckSet))) {
            throw new Error('Can not add duplicate data to array');
          }
          // @ts-ignore
          mainData[name] = arr.concat(data);
        } else {
          if (!check(data)) {
            throwForUpdateMaker(typeName, name, expected, data);
          }
          if (!canAdd(mainData, data)) {
            throw new Error(`Can not add duplicate data to ${typeName}`);
          }
          // @ts-ignore
          mainData[name] = data;
        }
      }
    }
  };
}
export const updateGlobal = updateMaker('global');
export const updateInput = updateMaker('input');
export const updateOutput = updateMaker('output');
export function addInputAttributes(inputs, data) {
  const index = inputs.length - 1;
  const input = checkForInput(inputs, index);
  updateInput(data, input);
}
export function addOutputAttributes(outputs, data) {
  const index = outputs.length - 1;
  const output = checkForOutput(outputs, index);
  updateOutput(data, output);
}
export function defaultVersionSetter(version, txBuf) {
  if (!(txBuf instanceof Uint8Array) || txBuf.length < 4) {
    throw new Error('Set Version: Invalid Transaction');
  }
  tools.writeUInt32(txBuf, 0, version, 'LE');
  return txBuf;
}
export function defaultLocktimeSetter(locktime, txBuf) {
  if (!(txBuf instanceof Uint8Array) || txBuf.length < 4) {
    throw new Error('Set Locktime: Invalid Transaction');
  }
  tools.writeUInt32(txBuf, txBuf.length - 4, locktime, 'LE');
  return txBuf;
}
