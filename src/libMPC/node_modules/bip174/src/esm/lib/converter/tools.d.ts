import { KeyValue } from '../interfaces';
export declare const range: (n: number) => number[];
export declare function reverseBuffer(buffer: Uint8Array): Uint8Array;
export declare function keyValsToBuffer(keyVals: KeyValue[]): Uint8Array;
export declare function keyValToBuffer(keyVal: KeyValue): Uint8Array;
