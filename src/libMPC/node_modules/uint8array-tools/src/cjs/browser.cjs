"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.readInt64 = exports.readInt32 = exports.readInt16 = exports.readInt8 = exports.writeInt64 = exports.writeInt32 = exports.writeInt16 = exports.writeInt8 = exports.readUInt64 = exports.readUInt32 = exports.readUInt16 = exports.readUInt8 = exports.writeUInt64 = exports.writeUInt32 = exports.writeUInt16 = exports.writeUInt8 = exports.compare = exports.fromBase64 = exports.toBase64 = exports.fromHex = exports.toHex = exports.concat = exports.fromUtf8 = exports.toUtf8 = void 0;
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
function toUtf8(bytes) {
    return DECODER.decode(bytes);
}
exports.toUtf8 = toUtf8;
function fromUtf8(s) {
    return ENCODER.encode(s);
}
exports.fromUtf8 = fromUtf8;
function concat(arrays) {
    const totalLength = arrays.reduce((a, b) => a + b.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const array of arrays) {
        result.set(array, offset);
        offset += array.length;
    }
    return result;
}
exports.concat = concat;
// There are two implementations.
// One optimizes for length of the bytes, and uses TextDecoder.
// One optimizes for iteration count, and appends strings.
// This removes the overhead of TextDecoder.
function toHex(bytes) {
    const b = bytes || new Uint8Array();
    return b.length > 512 ? _toHexLengthPerf(b) : _toHexIterPerf(b);
}
exports.toHex = toHex;
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
function fromHex(hexString) {
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
exports.fromHex = fromHex;
function toBase64(bytes) {
    return btoa(String.fromCharCode(...bytes));
}
exports.toBase64 = toBase64;
function fromBase64(base64) {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
}
exports.fromBase64 = fromBase64;
// Same behavior as Buffer.compare()
function compare(v1, v2) {
    const minLength = Math.min(v1.length, v2.length);
    for (let i = 0; i < minLength; ++i) {
        if (v1[i] !== v2[i]) {
            return v1[i] < v2[i] ? -1 : 1;
        }
    }
    return v1.length === v2.length ? 0 : v1.length > v2.length ? 1 : -1;
}
exports.compare = compare;
function writeUInt8(buffer, offset, value) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    if (value > 0xff) {
        throw new Error(`The value of "value" is out of range. It must be >= 0 and <= ${0xff}. Received ${value}`);
    }
    buffer[offset] = value;
    return offset + 1;
}
exports.writeUInt8 = writeUInt8;
function writeUInt16(buffer, offset, value, littleEndian) {
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
    return offset + 2;
}
exports.writeUInt16 = writeUInt16;
function writeUInt32(buffer, offset, value, littleEndian) {
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
    return offset + 4;
}
exports.writeUInt32 = writeUInt32;
function writeUInt64(buffer, offset, value, littleEndian) {
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
    return offset + 8;
}
exports.writeUInt64 = writeUInt64;
function readUInt8(buffer, offset) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    return buffer[offset];
}
exports.readUInt8 = readUInt8;
function readUInt16(buffer, offset, littleEndian) {
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
exports.readUInt16 = readUInt16;
function readUInt32(buffer, offset, littleEndian) {
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
exports.readUInt32 = readUInt32;
function readUInt64(buffer, offset, littleEndian) {
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
exports.readUInt64 = readUInt64;
function writeInt8(buffer, offset, value) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    if (value > 0x7f || value < -0x80) {
        throw new Error(`The value of "value" is out of range. It must be >= ${-0x80} and <= ${0x7f}. Received ${value}`);
    }
    buffer[offset] = value;
    return offset + 1;
}
exports.writeInt8 = writeInt8;
function writeInt16(buffer, offset, value, littleEndian) {
    if (offset + 2 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    if (value > 0x7fff || value < -0x8000) {
        throw new Error(`The value of "value" is out of range. It must be >= ${-0x8000} and <= ${0x7fff}. Received ${value}`);
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        buffer[offset] = value & 0xff;
        buffer[offset + 1] = (value >> 8) & 0xff;
    }
    else {
        buffer[offset] = (value >> 8) & 0xff;
        buffer[offset + 1] = value & 0xff;
    }
    return offset + 2;
}
exports.writeInt16 = writeInt16;
function writeInt32(buffer, offset, value, littleEndian) {
    if (offset + 4 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    if (value > 0x7fffffff || value < -0x80000000) {
        throw new Error(`The value of "value" is out of range. It must be >= ${-0x80000000} and <= ${0x7fffffff}. Received ${value}`);
    }
    littleEndian = littleEndian.toUpperCase();
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
    return offset + 4;
}
exports.writeInt32 = writeInt32;
function writeInt64(buffer, offset, value, littleEndian) {
    if (offset + 8 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    if (value > 0x7fffffffffffffffn || value < -0x8000000000000000n) {
        throw new Error(`The value of "value" is out of range. It must be >= ${-0x8000000000000000n} and <= ${0x7fffffffffffffffn}. Received ${value}`);
    }
    littleEndian = littleEndian.toUpperCase();
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
    return offset + 8;
}
exports.writeInt64 = writeInt64;
function readInt8(buffer, offset) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    const val = buffer[offset];
    if (val <= 0x7f) {
        return val;
    }
    else {
        return val - 0x100;
    }
}
exports.readInt8 = readInt8;
function readInt16(buffer, offset, littleEndian) {
    if (offset + 2 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        const val = buffer[offset] + (buffer[offset + 1] << 8);
        return buffer[offset + 1] <= 0x7f ? val : val - 0x10000;
    }
    else {
        const val = (buffer[offset] << 8) + buffer[offset + 1];
        return buffer[offset] <= 0x7f ? val : val - 0x10000;
    }
}
exports.readInt16 = readInt16;
function readInt32(buffer, offset, littleEndian) {
    if (offset + 4 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        const val = buffer[offset] +
            (buffer[offset + 1] << 8) +
            (buffer[offset + 2] << 16) +
            ((buffer[offset + 3] << 24) >>> 0);
        return buffer[offset + 3] <= 0x7f ? val : val - 0x100000000;
    }
    else {
        const val = ((buffer[offset] << 24) >>> 0) +
            (buffer[offset + 1] << 16) +
            (buffer[offset + 2] << 8) +
            buffer[offset + 3];
        return buffer[offset] <= 0x7f ? val : val - 0x100000000;
    }
}
exports.readInt32 = readInt32;
function readInt64(buffer, offset, littleEndian) {
    if (offset + 8 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    let num = 0n;
    if (littleEndian === "LE") {
        num = (num << 8n) + BigInt(buffer[offset + 7]);
        num = (num << 8n) + BigInt(buffer[offset + 6]);
        num = (num << 8n) + BigInt(buffer[offset + 5]);
        num = (num << 8n) + BigInt(buffer[offset + 4]);
        num = (num << 8n) + BigInt(buffer[offset + 3]);
        num = (num << 8n) + BigInt(buffer[offset + 2]);
        num = (num << 8n) + BigInt(buffer[offset + 1]);
        num = (num << 8n) + BigInt(buffer[offset]);
        return buffer[offset + 7] <= 0x7f ? num : num - 0x10000000000000000n;
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
        return buffer[offset] <= 0x7f ? num : num - 0x10000000000000000n;
    }
}
exports.readInt64 = readInt64;
