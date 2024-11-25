export var GlobalTypes;
(function(GlobalTypes) {
  GlobalTypes[(GlobalTypes['UNSIGNED_TX'] = 0)] = 'UNSIGNED_TX';
  GlobalTypes[(GlobalTypes['GLOBAL_XPUB'] = 1)] = 'GLOBAL_XPUB';
})(GlobalTypes || (GlobalTypes = {}));
export const GLOBAL_TYPE_NAMES = ['unsignedTx', 'globalXpub'];
export var InputTypes;
(function(InputTypes) {
  InputTypes[(InputTypes['NON_WITNESS_UTXO'] = 0)] = 'NON_WITNESS_UTXO';
  InputTypes[(InputTypes['WITNESS_UTXO'] = 1)] = 'WITNESS_UTXO';
  InputTypes[(InputTypes['PARTIAL_SIG'] = 2)] = 'PARTIAL_SIG';
  InputTypes[(InputTypes['SIGHASH_TYPE'] = 3)] = 'SIGHASH_TYPE';
  InputTypes[(InputTypes['REDEEM_SCRIPT'] = 4)] = 'REDEEM_SCRIPT';
  InputTypes[(InputTypes['WITNESS_SCRIPT'] = 5)] = 'WITNESS_SCRIPT';
  InputTypes[(InputTypes['BIP32_DERIVATION'] = 6)] = 'BIP32_DERIVATION';
  InputTypes[(InputTypes['FINAL_SCRIPTSIG'] = 7)] = 'FINAL_SCRIPTSIG';
  InputTypes[(InputTypes['FINAL_SCRIPTWITNESS'] = 8)] = 'FINAL_SCRIPTWITNESS';
  InputTypes[(InputTypes['POR_COMMITMENT'] = 9)] = 'POR_COMMITMENT';
  InputTypes[(InputTypes['TAP_KEY_SIG'] = 19)] = 'TAP_KEY_SIG';
  InputTypes[(InputTypes['TAP_SCRIPT_SIG'] = 20)] = 'TAP_SCRIPT_SIG';
  InputTypes[(InputTypes['TAP_LEAF_SCRIPT'] = 21)] = 'TAP_LEAF_SCRIPT';
  InputTypes[(InputTypes['TAP_BIP32_DERIVATION'] = 22)] =
    'TAP_BIP32_DERIVATION';
  InputTypes[(InputTypes['TAP_INTERNAL_KEY'] = 23)] = 'TAP_INTERNAL_KEY';
  InputTypes[(InputTypes['TAP_MERKLE_ROOT'] = 24)] = 'TAP_MERKLE_ROOT';
})(InputTypes || (InputTypes = {}));
export const INPUT_TYPE_NAMES = [
  'nonWitnessUtxo',
  'witnessUtxo',
  'partialSig',
  'sighashType',
  'redeemScript',
  'witnessScript',
  'bip32Derivation',
  'finalScriptSig',
  'finalScriptWitness',
  'porCommitment',
  'tapKeySig',
  'tapScriptSig',
  'tapLeafScript',
  'tapBip32Derivation',
  'tapInternalKey',
  'tapMerkleRoot',
];
export var OutputTypes;
(function(OutputTypes) {
  OutputTypes[(OutputTypes['REDEEM_SCRIPT'] = 0)] = 'REDEEM_SCRIPT';
  OutputTypes[(OutputTypes['WITNESS_SCRIPT'] = 1)] = 'WITNESS_SCRIPT';
  OutputTypes[(OutputTypes['BIP32_DERIVATION'] = 2)] = 'BIP32_DERIVATION';
  OutputTypes[(OutputTypes['TAP_INTERNAL_KEY'] = 5)] = 'TAP_INTERNAL_KEY';
  OutputTypes[(OutputTypes['TAP_TREE'] = 6)] = 'TAP_TREE';
  OutputTypes[(OutputTypes['TAP_BIP32_DERIVATION'] = 7)] =
    'TAP_BIP32_DERIVATION';
})(OutputTypes || (OutputTypes = {}));
export const OUTPUT_TYPE_NAMES = [
  'redeemScript',
  'witnessScript',
  'bip32Derivation',
  'tapInternalKey',
  'tapTree',
  'tapBip32Derivation',
];
