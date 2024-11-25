"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.compare = exports.fromHex = exports.toHex = void 0;
function toHex(bytes) {
    return Buffer.from(bytes || []).toString("hex");
}
exports.toHex = toHex;
function fromHex(hexString) {
    return Uint8Array.from(Buffer.from(hexString || "", "hex"));
}
exports.fromHex = fromHex;
function compare(v1, v2) {
    return Buffer.from(v1).compare(Buffer.from(v2));
}
exports.compare = compare;
