export function toUtf8(bytes) {
    return Buffer.from(bytes || []).toString();
}
export function fromUtf8(s) {
    return Uint8Array.from(Buffer.from(s || "", "utf8"));
}
export function concat(arrays) {
    return Uint8Array.from(Buffer.concat(arrays));
}
export function toHex(bytes) {
    return Buffer.from(bytes || []).toString("hex");
}
export function fromHex(hexString) {
    return Uint8Array.from(Buffer.from(hexString || "", "hex"));
}
export function toBase64(bytes) {
    return Buffer.from(bytes).toString("base64");
}
export function fromBase64(base64) {
    return Uint8Array.from(Buffer.from(base64 || "", "base64"));
}
export function compare(v1, v2) {
    return Buffer.from(v1).compare(Buffer.from(v2));
}
export function writeUInt8(buffer, offset, value) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    const buf = Buffer.alloc(1);
    buf.writeUInt8(value, 0);
    buffer.set(Uint8Array.from(buf), offset);
}
export function writeUInt16(buffer, offset, value, littleEndian) {
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
}
export function writeUInt32(buffer, offset, value, littleEndian) {
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
}
export function writeUInt64(buffer, offset, value, littleEndian) {
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
}
export function readUInt8(buffer, offset) {
    if (offset + 1 > buffer.length) {
        throw new Error("Offset is outside the bounds of Uint8Array");
    }
    const buf = Buffer.from(buffer);
    return buf.readUInt8(offset);
}
export function readUInt16(buffer, offset, littleEndian) {
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
export function readUInt32(buffer, offset, littleEndian) {
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
export function readUInt64(buffer, offset, littleEndian) {
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
