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
declare const globals: {
    unsignedTx: typeof unsignedTx;
    globalXpub: typeof globalXpub;
    checkPubkey: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array | undefined;
};
declare const inputs: {
    nonWitnessUtxo: typeof nonWitnessUtxo;
    partialSig: typeof partialSig;
    sighashType: typeof sighashType;
    finalScriptSig: typeof finalScriptSig;
    finalScriptWitness: typeof finalScriptWitness;
    porCommitment: typeof porCommitment;
    witnessUtxo: typeof witnessUtxo;
    bip32Derivation: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => import("../interfaces.js").Bip32Derivation;
        encode: (data: import("../interfaces.js").Bip32Derivation) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is import("../interfaces.js").Bip32Derivation;
        expected: string;
        canAddToArray: (array: import("../interfaces.js").Bip32Derivation[], item: import("../interfaces.js").Bip32Derivation, dupeSet: Set<string>) => boolean;
    };
    redeemScript: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array;
        encode: (data: Uint8Array) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is Uint8Array;
        expected: string;
        canAdd: (currentData: any, newData: any) => boolean;
    };
    witnessScript: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array;
        encode: (data: Uint8Array) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is Uint8Array;
        expected: string;
        canAdd: (currentData: any, newData: any) => boolean;
    };
    checkPubkey: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array | undefined;
    tapKeySig: typeof tapKeySig;
    tapScriptSig: typeof tapScriptSig;
    tapLeafScript: typeof tapLeafScript;
    tapBip32Derivation: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => import("../interfaces.js").TapBip32Derivation;
        encode: (data: import("../interfaces.js").TapBip32Derivation) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is import("../interfaces.js").TapBip32Derivation;
        expected: string;
        canAddToArray: (array: import("../interfaces.js").TapBip32Derivation[], item: import("../interfaces.js").TapBip32Derivation, dupeSet: Set<string>) => boolean;
    };
    tapInternalKey: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array;
        encode: (data: Uint8Array) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is Uint8Array;
        expected: string;
        canAdd: (currentData: any, newData: any) => boolean;
    };
    tapMerkleRoot: typeof tapMerkleRoot;
};
declare const outputs: {
    bip32Derivation: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => import("../interfaces.js").Bip32Derivation;
        encode: (data: import("../interfaces.js").Bip32Derivation) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is import("../interfaces.js").Bip32Derivation;
        expected: string;
        canAddToArray: (array: import("../interfaces.js").Bip32Derivation[], item: import("../interfaces.js").Bip32Derivation, dupeSet: Set<string>) => boolean;
    };
    redeemScript: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array;
        encode: (data: Uint8Array) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is Uint8Array;
        expected: string;
        canAdd: (currentData: any, newData: any) => boolean;
    };
    witnessScript: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array;
        encode: (data: Uint8Array) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is Uint8Array;
        expected: string;
        canAdd: (currentData: any, newData: any) => boolean;
    };
    checkPubkey: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array | undefined;
    tapBip32Derivation: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => import("../interfaces.js").TapBip32Derivation;
        encode: (data: import("../interfaces.js").TapBip32Derivation) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is import("../interfaces.js").TapBip32Derivation;
        expected: string;
        canAddToArray: (array: import("../interfaces.js").TapBip32Derivation[], item: import("../interfaces.js").TapBip32Derivation, dupeSet: Set<string>) => boolean;
    };
    tapTree: typeof tapTree;
    tapInternalKey: {
        decode: (keyVal: import("../interfaces.js").KeyValue) => Uint8Array;
        encode: (data: Uint8Array) => import("../interfaces.js").KeyValue;
        check: (data: any) => data is Uint8Array;
        expected: string;
        canAdd: (currentData: any, newData: any) => boolean;
    };
};
export { globals, inputs, outputs };
