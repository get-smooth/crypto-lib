import { KeyValue, PartialSig } from '../../interfaces';
export declare function decode(keyVal: KeyValue): PartialSig;
export declare function encode(pSig: PartialSig): KeyValue;
export declare const expected = "{ pubkey: Uint8Array; signature: Uint8Array; }";
export declare function check(data: any): data is PartialSig;
export declare function canAddToArray(array: PartialSig[], item: PartialSig, dupeSet: Set<string>): boolean;
