import { KeyValue, TapBip32Derivation } from '../../interfaces';
export declare function makeConverter(TYPE_BYTE: number): {
    decode: (keyVal: KeyValue) => TapBip32Derivation;
    encode: (data: TapBip32Derivation) => KeyValue;
    check: (data: any) => data is TapBip32Derivation;
    expected: string;
    canAddToArray: (array: TapBip32Derivation[], item: TapBip32Derivation, dupeSet: Set<string>) => boolean;
};
