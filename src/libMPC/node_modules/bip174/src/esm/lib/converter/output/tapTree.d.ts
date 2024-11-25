import { KeyValue, TapTree } from '../../interfaces';
export declare function decode(keyVal: KeyValue): TapTree;
export declare function encode(tree: TapTree): KeyValue;
export declare const expected = "{ leaves: [{ depth: number; leafVersion: number, script: Uint8Array; }] }";
export declare function check(data: any): data is TapTree;
export declare function canAdd(currentData: any, newData: any): boolean;
