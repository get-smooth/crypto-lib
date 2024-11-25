import { KeyValue, TapLeafScript } from '../../interfaces';
export declare function decode(keyVal: KeyValue): TapLeafScript;
export declare function encode(tScript: TapLeafScript): KeyValue;
export declare const expected = "{ controlBlock: Uint8Array; leafVersion: number, script: Uint8Array; }";
export declare function check(data: any): data is TapLeafScript;
export declare function canAddToArray(array: TapLeafScript[], item: TapLeafScript, dupeSet: Set<string>): boolean;
