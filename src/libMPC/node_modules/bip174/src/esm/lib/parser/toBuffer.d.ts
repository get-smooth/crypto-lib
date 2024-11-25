import { KeyValue } from '../interfaces';
import { PsbtAttributes } from './index.js';
export declare function psbtToBuffer({ globalMap, inputs, outputs, }: PsbtAttributes): Uint8Array;
export declare function psbtToKeyVals({ globalMap, inputs, outputs, }: PsbtAttributes): {
    globalKeyVals: KeyValue[];
    inputKeyVals: KeyValue[][];
    outputKeyVals: KeyValue[][];
};
