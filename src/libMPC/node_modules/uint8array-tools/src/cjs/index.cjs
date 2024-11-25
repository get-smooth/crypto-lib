"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.readInt64 = exports.readInt32 = exports.readInt16 = exports.readInt8 = exports.writeInt64 = exports.writeInt32 = exports.writeInt16 = exports.writeInt8 = exports.readUInt64 = exports.readUInt32 = exports.readUInt16 = exports.readUInt8 = exports.writeUInt64 = exports.writeUInt32 = exports.writeUInt16 = exports.writeUInt8 = exports.compare = exports.fromBase64 = exports.toBase64 = exports.fromHex = exports.toHex = exports.concat = exports.fromUtf8 = exports.toUtf8 = void 0;
function toUtf8(bytes) {
    return Buffer.from(bytes || []).toString();
}
exports.toUtf8 = toUtf8;
function fromUtf8(s) {
    return Uint8Array.from(Buffer.from(s || "", "utf8"));
}
exports.fromUtf8 = fromUtf8;
function concat(arrays) {
    return Uint8Array.from(Buffer.concat(arrays));
}
exports.concat = concat;
function toHex(bytes) {
    return Buffer.from(bytes || []).toString("hex");
}
exports.toHex = toHex;
function fromHex(hexString) {
    return Uint8Array.from(Buffer.from(hexString || "", "hex"));
}
exports.fromHex = fromHex;
function toBase64(bytes) {
    return Buffer.from(bytes).toString("base64");
}
exports.toBase64 = toBase64;
function fromBase64(base64) {
    return Uint8Array.from(Buffer.from(base64 || "", "base64"));
}
exports.fromBase64 = fromBase64;
function compare(v1, v2) {
    return Buffer.from(v1).compare(Buffer.from(v2));
}
exports.compare = compare;
function writeUInt8(buffer, offset, value) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    const buf = Buffer.alloc(1);
    buf.writeUInt8(value, 0);
    buffer.set(Uint8Array.from(buf), offset);
    return offset + 1;
}
exports.writeUInt8 = writeUInt8;
function writeUInt16(buffer, offset, value, littleEndian) {
    if (offset + 2 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    const buf = Buffer.alloc(2);
    if (littleEndian === "LE") {
        buf.writeUInt16LE(value, 0);
    }
    else {
        buf.writeUInt16BE(value, 0);
    }
    buffer.set(Uint8Array.from(buf), offset);
    return offset + 2;
}
exports.writeUInt16 = writeUInt16;
function writeUInt32(buffer, offset, value, littleEndian) {
    if (offset + 4 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    const buf = Buffer.alloc(4);
    if (littleEndian === "LE") {
        buf.writeUInt32LE(value, 0);
    }
    else {
        buf.writeUInt32BE(value, 0);
    }
    buffer.set(Uint8Array.from(buf), offset);
    return offset + 4;
}
exports.writeUInt32 = writeUInt32;
function writeUInt64(buffer, offset, value, littleEndian) {
    if (offset + 8 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    const buf = Buffer.alloc(8);
    if (value > 0xffffffffffffffffn) {
        throw new Error(`The value of "value" is out of range. It must be >= 0 and <= ${0xffffffffffffffffn}. Received ${value}`);
    }
    if (littleEndian === "LE") {
        buf.writeBigUInt64LE(value, 0);
    }
    else {
        buf.writeBigUInt64BE(value, 0);
    }
    buffer.set(Uint8Array.from(buf), offset);
    return offset + 8;
}
exports.writeUInt64 = writeUInt64;
function readUInt8(buffer, offset) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    const buf = Buffer.from(buffer);
    return buf.readUInt8(offset);
}
exports.readUInt8 = readUInt8;
function readUInt16(buffer, offset, littleEndian) {
    if (offset + 2 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    const buf = Buffer.from(buffer);
    if (littleEndian === "LE") {
        return buf.readUInt16LE(offset);
    }
    else {
        return buf.readUInt16BE(offset);
    }
}
exports.readUInt16 = readUInt16;
function readUInt32(buffer, offset, littleEndian) {
    if (offset + 4 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    const buf = Buffer.from(buffer);
    if (littleEndian === "LE") {
        return buf.readUInt32LE(offset);
    }
    else {
        return buf.readUInt32BE(offset);
    }
}
exports.readUInt32 = readUInt32;
function readUInt64(buffer, offset, littleEndian) {
    if (offset + 8 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    const buf = Buffer.from(buffer);
    if (littleEndian === "LE") {
        return buf.readBigUInt64LE(offset);
    }
    else {
        return buf.readBigUInt64BE(offset);
    }
}
exports.readUInt64 = readUInt64;
function writeInt8(buffer, offset, value) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    const buf = Buffer.alloc(1);
    buf.writeInt8(value, 0);
    buffer.set(Uint8Array.from(buf), offset);
    return offset + 1;
}
exports.writeInt8 = writeInt8;
function writeInt16(buffer, offset, value, littleEndian) {
    if (offset + 2 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    const buf = Buffer.alloc(2);
    if (littleEndian === "LE") {
        buf.writeInt16LE(value, 0);
    }
    else {
        buf.writeInt16BE(value, 0);
    }
    buffer.set(Uint8Array.from(buf), offset);
    return offset + 2;
}
exports.writeInt16 = writeInt16;
function writeInt32(buffer, offset, value, littleEndian) {
    if (offset + 4 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    const buf = Buffer.alloc(4);
    if (littleEndian === "LE") {
        buf.writeInt32LE(value, 0);
    }
    else {
        buf.writeInt32BE(value, 0);
    }
    buffer.set(Uint8Array.from(buf), offset);
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
    const buf = Buffer.alloc(8);
    if (littleEndian === "LE") {
        buf.writeBigInt64LE(value, 0);
    }
    else {
        buf.writeBigInt64BE(value, 0);
    }
    buffer.set(Uint8Array.from(buf), offset);
    return offset + 8;
}
exports.writeInt64 = writeInt64;
function readInt8(buffer, offset) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    const buf = Buffer.from(buffer);
    return buf.readInt8(offset);
}
exports.readInt8 = readInt8;
function readInt16(buffer, offset, littleEndian) {
    if (offset + 2 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        return Buffer.from(buffer).readInt16LE(offset);
    }
    else {
        return Buffer.from(buffer).readInt16BE(offset);
    }
}
exports.readInt16 = readInt16;
function readInt32(buffer, offset, littleEndian) {
    if (offset + 4 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        return Buffer.from(buffer).readInt32LE(offset);
    }
    else {
        return Buffer.from(buffer).readInt32BE(offset);
    }
}
exports.readInt32 = readInt32;
function readInt64(buffer, offset, littleEndian) {
    if (offset + 8 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    littleEndian = littleEndian.toUpperCase();
    if (littleEndian === "LE") {
        return Buffer.from(buffer).readBigInt64LE(offset);
    }
    else {
        return Buffer.from(buffer).readBigInt64BE(offset);
    }
}
exports.readInt64 = readInt64;
