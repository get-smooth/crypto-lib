import { PsbtGlobal, PsbtInput, PsbtOutput } from '../interfaces';
export * from './fromBuffer.js';
export * from './toBuffer.js';
export interface PsbtAttributes {
    globalMap: PsbtGlobal;
    inputs: PsbtInput[];
    outputs: PsbtOutput[];
}
