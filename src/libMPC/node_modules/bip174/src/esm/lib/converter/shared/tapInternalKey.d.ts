import { KeyValue, TapInternalKey } from '../../interfaces';
export declare function makeConverter(TYPE_BYTE: number): {
    decode: (keyVal: KeyValue) => TapInternalKey;
    encode: (data: TapInternalKey) => KeyValue;
    check: (data: any) => data is TapInternalKey;
    expected: string;
    canAdd: (currentData: any, newData: any) => boolean;
};
