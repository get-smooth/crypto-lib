const HEX_STRINGS = "0123456789abcdefABCDEF";
const HEX_CODES = HEX_STRINGS.split("").map((c) => c.codePointAt(0));
const HEX_CODEPOINTS = Array(256)
    .fill(true)
    .map((_, i) => {
    const s = String.fromCodePoint(i);
    const index = HEX_STRINGS.indexOf(s);
    // ABCDEF will use 10 - 15
    return index < 0 ? undefined : index < 16 ? index : index - 6;
});
const ENCODER = new TextEncoder();
const DECODER = new TextDecoder("ascii");
// There are two implementations.
// One optimizes for length of the bytes, and uses TextDecoder.
// One optimizes for iteration count, and appends strings.
// This removes the overhead of TextDecoder.
export function toHex(bytes) {
    const b = bytes || new Uint8Array();
    return b.length > 512 ? _toHexLengthPerf(b) : _toHexIterPerf(b);
}
function _toHexIterPerf(bytes) {
    let s = "";
    for (let i = 0; i < bytes.length; ++i) {
        s += HEX_STRINGS[HEX_CODEPOINTS[HEX_CODES[bytes[i] >> 4]]];
        s += HEX_STRINGS[HEX_CODEPOINTS[HEX_CODES[bytes[i] & 15]]];
    }
    return s;
}
function _toHexLengthPerf(bytes) {
    const hexBytes = new Uint8Array(bytes.length * 2);
    for (let i = 0; i < bytes.length; ++i) {
        hexBytes[i * 2] = HEX_CODES[bytes[i] >> 4];
        hexBytes[i * 2 + 1] = HEX_CODES[bytes[i] & 15];
    }
    return DECODER.decode(hexBytes);
}
// Mimics Buffer.from(x, 'hex') logic
// Stops on first non-hex string and returns
// https://github.com/nodejs/node/blob/v14.18.1/src/string_bytes.cc#L246-L261
export function fromHex(hexString) {
    const hexBytes = ENCODER.encode(hexString || "");
    const resultBytes = new Uint8Array(Math.floor(hexBytes.length / 2));
    let i;
    for (i = 0; i < resultBytes.length; i++) {
        const a = HEX_CODEPOINTS[hexBytes[i * 2]];
        const b = HEX_CODEPOINTS[hexBytes[i * 2 + 1]];
        if (a === undefined || b === undefined) {
            break;
        }
        resultBytes[i] = (a << 4) | b;
    }
    return i === resultBytes.length ? resultBytes : resultBytes.slice(0, i);
}
// Same behavior as Buffer.compare()
export function compare(v1, v2) {
    const minLength = Math.min(v1.length, v2.length);
    for (let i = 0; i < minLength; ++i) {
        if (v1[i] !== v2[i]) {
            return v1[i] < v2[i] ? -1 : 1;
        }
    }
    return v1.length === v2.length ? 0 : v1.length > v2.length ? 1 : -1;
}
