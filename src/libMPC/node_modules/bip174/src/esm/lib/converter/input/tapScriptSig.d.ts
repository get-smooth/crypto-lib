import { KeyValue, TapScriptSig } from '../../interfaces';
export declare function decode(keyVal: KeyValue): TapScriptSig;
export declare function encode(tSig: TapScriptSig): KeyValue;
export declare const expected = "{ pubkey: Uint8Array; leafHash: Uint8Array; signature: Uint8Array; }";
export declare function check(data: any): data is TapScriptSig;
export declare function canAddToArray(array: TapScriptSig[], item: TapScriptSig, dupeSet: Set<string>): boolean;
