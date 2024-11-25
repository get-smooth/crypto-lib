export declare enum GlobalTypes {
    UNSIGNED_TX = 0,
    GLOBAL_XPUB = 1
}
export declare const GLOBAL_TYPE_NAMES: string[];
export declare enum InputTypes {
    NON_WITNESS_UTXO = 0,
    WITNESS_UTXO = 1,
    PARTIAL_SIG = 2,
    SIGHASH_TYPE = 3,
    REDEEM_SCRIPT = 4,
    WITNESS_SCRIPT = 5,
    BIP32_DERIVATION = 6,
    FINAL_SCRIPTSIG = 7,
    FINAL_SCRIPTWITNESS = 8,
    POR_COMMITMENT = 9,
    TAP_KEY_SIG = 19,
    TAP_SCRIPT_SIG = 20,
    TAP_LEAF_SCRIPT = 21,
    TAP_BIP32_DERIVATION = 22,
    TAP_INTERNAL_KEY = 23,
    TAP_MERKLE_ROOT = 24
}
export declare const INPUT_TYPE_NAMES: string[];
export declare enum OutputTypes {
    REDEEM_SCRIPT = 0,
    WITNESS_SCRIPT = 1,
    BIP32_DERIVATION = 2,
    TAP_INTERNAL_KEY = 5,
    TAP_TREE = 6,
    TAP_BIP32_DERIVATION = 7
}
export declare const OUTPUT_TYPE_NAMES: string[];
