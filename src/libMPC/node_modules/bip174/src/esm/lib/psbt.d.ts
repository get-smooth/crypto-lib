import { KeyValue, PsbtGlobal, PsbtGlobalUpdate, PsbtInput, PsbtInputExtended, PsbtInputUpdate, PsbtOutput, PsbtOutputExtended, PsbtOutputUpdate, Transaction, TransactionFromBuffer } from './interfaces.js';
export declare class Psbt {
    static fromBase64<T extends typeof Psbt>(this: T, data: string, txFromBuffer: TransactionFromBuffer): InstanceType<T>;
    static fromHex<T extends typeof Psbt>(this: T, data: string, txFromBuffer: TransactionFromBuffer): InstanceType<T>;
    static fromBuffer<T extends typeof Psbt>(this: T, buffer: Uint8Array, txFromBuffer: TransactionFromBuffer): InstanceType<T>;
    readonly inputs: PsbtInput[];
    readonly outputs: PsbtOutput[];
    readonly globalMap: PsbtGlobal;
    constructor(tx: Transaction);
    toBase64(): string;
    toHex(): string;
    toBuffer(): Uint8Array;
    updateGlobal(updateData: PsbtGlobalUpdate): this;
    updateInput(inputIndex: number, updateData: PsbtInputUpdate): this;
    updateOutput(outputIndex: number, updateData: PsbtOutputUpdate): this;
    addUnknownKeyValToGlobal(keyVal: KeyValue): this;
    addUnknownKeyValToInput(inputIndex: number, keyVal: KeyValue): this;
    addUnknownKeyValToOutput(outputIndex: number, keyVal: KeyValue): this;
    addInput(inputData: PsbtInputExtended): this;
    addOutput(outputData: PsbtOutputExtended): this;
    clearFinalizedInput(inputIndex: number): this;
    combine(...those: this[]): this;
    getTransaction(): Uint8Array;
}
export { Bip32Derivation, NonWitnessUtxo, ControlBlock, FinalScriptSig, FinalScriptWitness, GlobalXpub, KeyValue, PartialSig, PorCommitment, PsbtGlobal, PsbtGlobalUpdate, PsbtInput, PsbtInputExtended, PsbtInputUpdate, PsbtOutput, PsbtOutputExtended, PsbtOutputUpdate, RedeemScript, SighashType, TapBip32Derivation, TapInternalKey, TapKeySig, TapLeaf, TapLeafScript, TapMerkleRoot, TapScriptSig, TapTree, Transaction, TransactionFromBuffer, TransactionIOCountGetter, TransactionLocktimeSetter, TransactionVersionSetter, WitnessScript, WitnessUtxo, } from './interfaces.js';
export { checkForInput, checkForOutput } from './utils.js';
