'use strict';
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.encode = encode;
exports.decode = decode;
exports.encodingLength = encodingLength;
const tools = __importStar(require("uint8array-tools"));
const checkUInt64 = (n) => {
    if (n < 0 || n > 0xffffffffffffffffn) {
        throw new RangeError('value out of range');
    }
};
function checkUInt53(n) {
    if (n < 0 || n > Number.MAX_SAFE_INTEGER || n % 1 !== 0)
        throw new RangeError('value out of range');
}
function checkUint53OrUint64(n) {
    if (typeof n === 'number')
        checkUInt53(n);
    else
        checkUInt64(n);
}
function encode(n, buffer, offset) {
    checkUint53OrUint64(n);
    if (offset === undefined)
        offset = 0;
    if (buffer === undefined) {
        buffer = new Uint8Array(encodingLength(n));
    }
    let bytes = 0;
    // 8 bit
    if (n < 0xfd) {
        buffer.set([Number(n)], offset);
        bytes = 1;
        // 16 bit
    }
    else if (n <= 0xffff) {
        buffer.set([0xfd], offset);
        tools.writeUInt16(buffer, offset + 1, Number(n), 'LE');
        bytes = 3;
        // 32 bit
    }
    else if (n <= 0xffffffff) {
        buffer.set([0xfe], offset);
        tools.writeUInt32(buffer, offset + 1, Number(n), 'LE');
        bytes = 5;
        // 64 bit
    }
    else {
        buffer.set([0xff], offset);
        tools.writeUInt64(buffer, offset + 1, BigInt(n), 'LE');
        bytes = 9;
    }
    return { buffer, bytes };
}
function decode(buffer, offset) {
    if (offset === undefined)
        offset = 0;
    const first = buffer.at(offset);
    if (first === undefined)
        throw new Error('buffer too small');
    // 8 bit
    if (first < 0xfd) {
        return { numberValue: first, bigintValue: BigInt(first), bytes: 1 };
        // 16 bit
    }
    else if (first === 0xfd) {
        const val = tools.readUInt16(buffer, offset + 1, 'LE');
        return {
            numberValue: val,
            bigintValue: BigInt(val),
            bytes: 3
        };
        // 32 bit
    }
    else if (first === 0xfe) {
        const val = tools.readUInt32(buffer, offset + 1, 'LE');
        return {
            numberValue: val,
            bigintValue: BigInt(val),
            bytes: 5
        };
        // 64 bit
    }
    else {
        const number = tools.readUInt64(buffer, offset + 1, 'LE');
        return { numberValue: number <= Number.MAX_SAFE_INTEGER ? Number(number) : null, bigintValue: number, bytes: 9 };
    }
}
function encodingLength(n) {
    checkUint53OrUint64(n);
    return n < 0xfd ? 1 : n <= 0xffff ? 3 : n <= 0xffffffff ? 5 : 9;
}
