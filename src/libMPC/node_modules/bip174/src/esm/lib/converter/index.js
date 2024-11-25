import { InputTypes, OutputTypes } from '../typeFields.js';
import * as globalXpub from './global/globalXpub.js';
import * as unsignedTx from './global/unsignedTx.js';
import * as finalScriptSig from './input/finalScriptSig.js';
import * as finalScriptWitness from './input/finalScriptWitness.js';
import * as nonWitnessUtxo from './input/nonWitnessUtxo.js';
import * as partialSig from './input/partialSig.js';
import * as porCommitment from './input/porCommitment.js';
import * as sighashType from './input/sighashType.js';
import * as tapKeySig from './input/tapKeySig.js';
import * as tapLeafScript from './input/tapLeafScript.js';
import * as tapMerkleRoot from './input/tapMerkleRoot.js';
import * as tapScriptSig from './input/tapScriptSig.js';
import * as witnessUtxo from './input/witnessUtxo.js';
import * as tapTree from './output/tapTree.js';
import * as bip32Derivation from './shared/bip32Derivation.js';
import * as checkPubkey from './shared/checkPubkey.js';
import * as redeemScript from './shared/redeemScript.js';
import * as tapBip32Derivation from './shared/tapBip32Derivation.js';
import * as tapInternalKey from './shared/tapInternalKey.js';
import * as witnessScript from './shared/witnessScript.js';
const globals = {
  unsignedTx,
  globalXpub,
  // pass an Array of key bytes that require pubkey beside the key
  checkPubkey: checkPubkey.makeChecker([]),
};
const inputs = {
  nonWitnessUtxo,
  partialSig,
  sighashType,
  finalScriptSig,
  finalScriptWitness,
  porCommitment,
  witnessUtxo,
  bip32Derivation: bip32Derivation.makeConverter(InputTypes.BIP32_DERIVATION),
  redeemScript: redeemScript.makeConverter(InputTypes.REDEEM_SCRIPT),
  witnessScript: witnessScript.makeConverter(InputTypes.WITNESS_SCRIPT),
  checkPubkey: checkPubkey.makeChecker([
    InputTypes.PARTIAL_SIG,
    InputTypes.BIP32_DERIVATION,
  ]),
  tapKeySig,
  tapScriptSig,
  tapLeafScript,
  tapBip32Derivation: tapBip32Derivation.makeConverter(
    InputTypes.TAP_BIP32_DERIVATION,
  ),
  tapInternalKey: tapInternalKey.makeConverter(InputTypes.TAP_INTERNAL_KEY),
  tapMerkleRoot,
};
const outputs = {
  bip32Derivation: bip32Derivation.makeConverter(OutputTypes.BIP32_DERIVATION),
  redeemScript: redeemScript.makeConverter(OutputTypes.REDEEM_SCRIPT),
  witnessScript: witnessScript.makeConverter(OutputTypes.WITNESS_SCRIPT),
  checkPubkey: checkPubkey.makeChecker([OutputTypes.BIP32_DERIVATION]),
  tapBip32Derivation: tapBip32Derivation.makeConverter(
    OutputTypes.TAP_BIP32_DERIVATION,
  ),
  tapTree,
  tapInternalKey: tapInternalKey.makeConverter(OutputTypes.TAP_INTERNAL_KEY),
};
export { globals, inputs, outputs };
