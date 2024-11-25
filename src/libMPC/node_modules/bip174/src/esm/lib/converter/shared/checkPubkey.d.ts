import { KeyValue } from '../../interfaces';
export declare function makeChecker(pubkeyTypes: number[]): (keyVal: KeyValue) => Uint8Array | undefined;
