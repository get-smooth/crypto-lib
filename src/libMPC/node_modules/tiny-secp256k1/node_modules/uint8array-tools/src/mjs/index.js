export function toHex(bytes) {
    return Buffer.from(bytes || []).toString("hex");
}
export function fromHex(hexString) {
    return Uint8Array.from(Buffer.from(hexString || "", "hex"));
}
export function compare(v1, v2) {
    return Buffer.from(v1).compare(Buffer.from(v2));
}
