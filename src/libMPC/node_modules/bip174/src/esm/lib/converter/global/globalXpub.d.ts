import { GlobalXpub, KeyValue } from '../../interfaces';
export declare function decode(keyVal: KeyValue): GlobalXpub;
export declare function encode(data: GlobalXpub): KeyValue;
export declare const expected = "{ masterFingerprint: Uint8Array; extendedPubkey: Uint8Array; path: string; }";
export declare function check(data: any): data is GlobalXpub;
export declare function canAddToArray(array: GlobalXpub[], item: GlobalXpub, dupeSet: Set<string>): boolean;
