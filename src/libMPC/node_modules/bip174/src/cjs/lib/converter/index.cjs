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
const typeFields_js_1 = require('../typeFields.cjs');
const globalXpub = __importStar(require('./global/globalXpub.cjs'));
const unsignedTx = __importStar(require('./global/unsignedTx.cjs'));
const finalScriptSig = __importStar(require('./input/finalScriptSig.cjs'));
const finalScriptWitness = __importStar(
  require('./input/finalScriptWitness.cjs'),
);
const nonWitnessUtxo = __importStar(require('./input/nonWitnessUtxo.cjs'));
const partialSig = __importStar(require('./input/partialSig.cjs'));
const porCommitment = __importStar(require('./input/porCommitment.cjs'));
const sighashType = __importStar(require('./input/sighashType.cjs'));
const tapKeySig = __importStar(require('./input/tapKeySig.cjs'));
const tapLeafScript = __importStar(require('./input/tapLeafScript.cjs'));
const tapMerkleRoot = __importStar(require('./input/tapMerkleRoot.cjs'));
const tapScriptSig = __importStar(require('./input/tapScriptSig.cjs'));
const witnessUtxo = __importStar(require('./input/witnessUtxo.cjs'));
const tapTree = __importStar(require('./output/tapTree.cjs'));
const bip32Derivation = __importStar(require('./shared/bip32Derivation.cjs'));
const checkPubkey = __importStar(require('./shared/checkPubkey.cjs'));
const redeemScript = __importStar(require('./shared/redeemScript.cjs'));
const tapBip32Derivation = __importStar(
  require('./shared/tapBip32Derivation.cjs'),
);
const tapInternalKey = __importStar(require('./shared/tapInternalKey.cjs'));
const witnessScript = __importStar(require('./shared/witnessScript.cjs'));
const globals = {
  unsignedTx,
  globalXpub,
  // pass an Array of key bytes that require pubkey beside the key
  checkPubkey: checkPubkey.makeChecker([]),
};
exports.globals = globals;
const inputs = {
  nonWitnessUtxo,
  partialSig,
  sighashType,
  finalScriptSig,
  finalScriptWitness,
  porCommitment,
  witnessUtxo,
  bip32Derivation: bip32Derivation.makeConverter(
    typeFields_js_1.InputTypes.BIP32_DERIVATION,
  ),
  redeemScript: redeemScript.makeConverter(
    typeFields_js_1.InputTypes.REDEEM_SCRIPT,
  ),
  witnessScript: witnessScript.makeConverter(
    typeFields_js_1.InputTypes.WITNESS_SCRIPT,
  ),
  checkPubkey: checkPubkey.makeChecker([
    typeFields_js_1.InputTypes.PARTIAL_SIG,
    typeFields_js_1.InputTypes.BIP32_DERIVATION,
  ]),
  tapKeySig,
  tapScriptSig,
  tapLeafScript,
  tapBip32Derivation: tapBip32Derivation.makeConverter(
    typeFields_js_1.InputTypes.TAP_BIP32_DERIVATION,
  ),
  tapInternalKey: tapInternalKey.makeConverter(
    typeFields_js_1.InputTypes.TAP_INTERNAL_KEY,
  ),
  tapMerkleRoot,
};
exports.inputs = inputs;
const outputs = {
  bip32Derivation: bip32Derivation.makeConverter(
    typeFields_js_1.OutputTypes.BIP32_DERIVATION,
  ),
  redeemScript: redeemScript.makeConverter(
    typeFields_js_1.OutputTypes.REDEEM_SCRIPT,
  ),
  witnessScript: witnessScript.makeConverter(
    typeFields_js_1.OutputTypes.WITNESS_SCRIPT,
  ),
  checkPubkey: checkPubkey.makeChecker([
    typeFields_js_1.OutputTypes.BIP32_DERIVATION,
  ]),
  tapBip32Derivation: tapBip32Derivation.makeConverter(
    typeFields_js_1.OutputTypes.TAP_BIP32_DERIVATION,
  ),
  tapTree,
  tapInternalKey: tapInternalKey.makeConverter(
    typeFields_js_1.OutputTypes.TAP_INTERNAL_KEY,
  ),
};
exports.outputs = outputs;
