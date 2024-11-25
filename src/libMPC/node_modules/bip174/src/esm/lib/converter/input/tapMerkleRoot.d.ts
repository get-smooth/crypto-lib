import { KeyValue, TapMerkleRoot } from '../../interfaces';
export declare function decode(keyVal: KeyValue): TapMerkleRoot;
export declare function encode(value: TapMerkleRoot): KeyValue;
export declare const expected = "Uint8Array";
export declare function check(data: any): data is TapMerkleRoot;
export declare function canAdd(currentData: any, newData: any): boolean;
