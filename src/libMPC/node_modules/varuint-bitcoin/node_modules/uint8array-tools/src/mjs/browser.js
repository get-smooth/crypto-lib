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
const DECODER = new TextDecoder();
export function toUtf8(bytes) {
    return DECODER.decode(bytes);
}
export function fromUtf8(s) {
    return ENCODER.encode(s);
}
export function concat(arrays) {
    const totalLength = arrays.reduce((a, b) => a + b.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const array of arrays) {
        result.set(array, offset);
        offset += array.length;
    }
    return result;
}
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
export function toBase64(bytes) {
    return btoa(String.fromCharCode(...bytes));
}
export function fromBase64(base64) {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
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
export function writeUInt8(buffer, offset, value) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    if (value > 0xff) {
        throw new Error(`The value of "value" is out of range. It must be >= 0 and <= ${0xff}. Received ${value}`);
    }
    buffer[offset] = value;
}
export function writeUInt16(buffer, offset, value, littleEndian) {
    if (offset + 2 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (value > 0xffff) {
        throw new Error(`The value of "value" is out of range. It must be >= 0 and <= ${0xffff}. Received ${value}`);
    }
    if (littleEndian === "LE") {
        buffer[offset] = value & 0xff;
        buffer[offset + 1] = (value >> 8) & 0xff;
    }
    else {
        buffer[offset] = (value >> 8) & 0xff;
        buffer[offset + 1] = value & 0xff;
    }
}
export function writeUInt32(buffer, offset, value, littleEndian) {
    if (offset + 4 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (value > 0xffffffff) {
        throw new Error(`The value of "value" is out of range. It must be >= 0 and <= ${0xffffffff}. Received ${value}`);
    }
    if (littleEndian === "LE") {
        buffer[offset] = value & 0xff;
        buffer[offset + 1] = (value >> 8) & 0xff;
        buffer[offset + 2] = (value >> 16) & 0xff;
        buffer[offset + 3] = (value >> 24) & 0xff;
    }
    else {
        buffer[offset] = (value >> 24) & 0xff;
        buffer[offset + 1] = (value >> 16) & 0xff;
        buffer[offset + 2] = (value >> 8) & 0xff;
        buffer[offset + 3] = value & 0xff;
    }
}
export function writeUInt64(buffer, offset, value, littleEndian) {
    if (offset + 8 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (value > 0xffffffffffffffffn) {
        throw new Error(`The value of "value" is out of range. It must be >= 0 and <= ${0xffffffffffffffffn}. Received ${value}`);
    }
    if (littleEndian === "LE") {
        buffer[offset] = Number(value & 0xffn);
        buffer[offset + 1] = Number((value >> 8n) & 0xffn);
        buffer[offset + 2] = Number((value >> 16n) & 0xffn);
        buffer[offset + 3] = Number((value >> 24n) & 0xffn);
        buffer[offset + 4] = Number((value >> 32n) & 0xffn);
        buffer[offset + 5] = Number((value >> 40n) & 0xffn);
        buffer[offset + 6] = Number((value >> 48n) & 0xffn);
        buffer[offset + 7] = Number((value >> 56n) & 0xffn);
    }
    else {
        buffer[offset] = Number((value >> 56n) & 0xffn);
        buffer[offset + 1] = Number((value >> 48n) & 0xffn);
        buffer[offset + 2] = Number((value >> 40n) & 0xffn);
        buffer[offset + 3] = Number((value >> 32n) & 0xffn);
        buffer[offset + 4] = Number((value >> 24n) & 0xffn);
        buffer[offset + 5] = Number((value >> 16n) & 0xffn);
        buffer[offset + 6] = Number((value >> 8n) & 0xffn);
        buffer[offset + 7] = Number(value & 0xffn);
    }
}
export function readUInt8(buffer, offset) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    return buffer[offset];
}
export function readUInt16(buffer, offset, littleEndian) {
    if (offset + 2 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        let num = 0;
        num = (num << 8) + buffer[offset + 1];
        num = (num << 8) + buffer[offset];
        return num;
    }
    else {
        let num = 0;
        num = (num << 8) + buffer[offset];
        num = (num << 8) + buffer[offset + 1];
        return num;
    }
}
export function readUInt32(buffer, offset, littleEndian) {
    if (offset + 4 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        let num = 0;
        num = ((num << 8) + buffer[offset + 3]) >>> 0;
        num = ((num << 8) + buffer[offset + 2]) >>> 0;
        num = ((num << 8) + buffer[offset + 1]) >>> 0;
        num = ((num << 8) + buffer[offset]) >>> 0;
        return num;
    }
    else {
        let num = 0;
        num = ((num << 8) + buffer[offset]) >>> 0;
        num = ((num << 8) + buffer[offset + 1]) >>> 0;
        num = ((num << 8) + buffer[offset + 2]) >>> 0;
        num = ((num << 8) + buffer[offset + 3]) >>> 0;
        return num;
    }
}
export function readUInt64(buffer, offset, littleEndian) {
    if (offset + 8 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        let num = 0n;
        num = (num << 8n) + BigInt(buffer[offset + 7]);
        num = (num << 8n) + BigInt(buffer[offset + 6]);
        num = (num << 8n) + BigInt(buffer[offset + 5]);
        num = (num << 8n) + BigInt(buffer[offset + 4]);
        num = (num << 8n) + BigInt(buffer[offset + 3]);
        num = (num << 8n) + BigInt(buffer[offset + 2]);
        num = (num << 8n) + BigInt(buffer[offset + 1]);
        num = (num << 8n) + BigInt(buffer[offset]);
        return num;
    }
    else {
        let num = 0n;
        num = (num << 8n) + BigInt(buffer[offset]);
        num = (num << 8n) + BigInt(buffer[offset + 1]);
        num = (num << 8n) + BigInt(buffer[offset + 2]);
        num = (num << 8n) + BigInt(buffer[offset + 3]);
        num = (num << 8n) + BigInt(buffer[offset + 4]);
        num = (num << 8n) + BigInt(buffer[offset + 5]);
        num = (num << 8n) + BigInt(buffer[offset + 6]);
        num = (num << 8n) + BigInt(buffer[offset + 7]);
        return num;
    }
}
