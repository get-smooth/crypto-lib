import { KeyValue, Transaction, TransactionFromBuffer } from '../interfaces';
import { PsbtAttributes } from './index.js';
export declare function psbtFromBuffer(buffer: Uint8Array, txGetter: TransactionFromBuffer): PsbtAttributes;
interface PsbtFromKeyValsArg {
    globalMapKeyVals: KeyValue[];
    inputKeyVals: KeyValue[][];
    outputKeyVals: KeyValue[][];
}
export declare function checkKeyBuffer(type: string, keyBuf: Uint8Array, keyNum: number): void;
export declare function psbtFromKeyVals(unsignedTx: Transaction, { globalMapKeyVals, inputKeyVals, outputKeyVals }: PsbtFromKeyValsArg): PsbtAttributes;
export {};
