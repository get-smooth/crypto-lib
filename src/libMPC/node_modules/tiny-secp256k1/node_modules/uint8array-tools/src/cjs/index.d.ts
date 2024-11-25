export declare function toHex(bytes: Uint8Array): string;
export declare function fromHex(hexString: string): Uint8Array;
export declare type CompareResult = -1 | 0 | 1;
export declare function compare(v1: Uint8Array, v2: Uint8Array): CompareResult;
