export declare type TransactionFromBuffer = (buffer: Uint8Array) => Transaction;
export interface Transaction {
    getInputOutputCounts(): {
        inputCount: number;
        outputCount: number;
    };
    addInput(objectArg: any): void;
    addOutput(objectArg: any): void;
    toBuffer(): Uint8Array;
}
export interface KeyValue {
    key: Uint8Array;
    value: Uint8Array;
}
export interface PsbtGlobal extends PsbtGlobalUpdate {
    unsignedTx: Transaction;
    unknownKeyVals?: KeyValue[];
}
export interface PsbtGlobalUpdate {
    globalXpub?: GlobalXpub[];
}
export interface PsbtInput extends PsbtInputUpdate {
    unknownKeyVals?: KeyValue[];
}
export interface PsbtInputUpdate {
    partialSig?: PartialSig[];
    nonWitnessUtxo?: NonWitnessUtxo;
    witnessUtxo?: WitnessUtxo;
    sighashType?: SighashType;
    redeemScript?: RedeemScript;
    witnessScript?: WitnessScript;
    bip32Derivation?: Bip32Derivation[];
    finalScriptSig?: FinalScriptSig;
    finalScriptWitness?: FinalScriptWitness;
    porCommitment?: PorCommitment;
    tapKeySig?: TapKeySig;
    tapScriptSig?: TapScriptSig[];
    tapLeafScript?: TapLeafScript[];
    tapBip32Derivation?: TapBip32Derivation[];
    tapInternalKey?: TapInternalKey;
    tapMerkleRoot?: TapMerkleRoot;
}
export interface PsbtInputExtended extends PsbtInput {
    [index: string]: any;
}
export interface PsbtOutput extends PsbtOutputUpdate {
    unknownKeyVals?: KeyValue[];
}
export interface PsbtOutputUpdate {
    redeemScript?: RedeemScript;
    witnessScript?: WitnessScript;
    bip32Derivation?: Bip32Derivation[];
    tapBip32Derivation?: TapBip32Derivation[];
    tapTree?: TapTree;
    tapInternalKey?: TapInternalKey;
}
export interface PsbtOutputExtended extends PsbtOutput {
    [index: string]: any;
}
export interface GlobalXpub {
    extendedPubkey: Uint8Array;
    masterFingerprint: Uint8Array;
    path: string;
}
export interface PartialSig {
    pubkey: Uint8Array;
    signature: Uint8Array;
}
export interface Bip32Derivation {
    masterFingerprint: Uint8Array;
    pubkey: Uint8Array;
    path: string;
}
export interface WitnessUtxo {
    script: Uint8Array;
    value: bigint;
}
export declare type NonWitnessUtxo = Uint8Array;
export declare type SighashType = number;
export declare type RedeemScript = Uint8Array;
export declare type WitnessScript = Uint8Array;
export declare type FinalScriptSig = Uint8Array;
export declare type FinalScriptWitness = Uint8Array;
export declare type PorCommitment = string;
export declare type TapKeySig = Uint8Array;
export interface TapScriptSig extends PartialSig {
    leafHash: Uint8Array;
}
interface TapScript {
    leafVersion: number;
    script: Uint8Array;
}
export declare type ControlBlock = Uint8Array;
export interface TapLeafScript extends TapScript {
    controlBlock: ControlBlock;
}
export interface TapBip32Derivation extends Bip32Derivation {
    leafHashes: Uint8Array[];
}
export declare type TapInternalKey = Uint8Array;
export declare type TapMerkleRoot = Uint8Array;
export interface TapLeaf extends TapScript {
    depth: number;
}
export interface TapTree {
    leaves: TapLeaf[];
}
export declare type TransactionIOCountGetter = (txBuffer: Uint8Array) => {
    inputCount: number;
    outputCount: number;
};
export declare type TransactionVersionSetter = (version: number, txBuffer: Uint8Array) => Uint8Array;
export declare type TransactionLocktimeSetter = (locktime: number, txBuffer: Uint8Array) => Uint8Array;
export {};
