export declare function encode(n: number | bigint, buffer?: Uint8Array, offset?: number): {
    buffer: Uint8Array;
    bytes: number;
};
export declare function decode(buffer: Uint8Array, offset?: number): {
    numberValue: number | null;
    bigintValue: bigint;
    bytes: number;
};
export declare function encodingLength(n: number | bigint): number;
