# Uint8Array Tools

This library is licensed under MIT.

## Usage

Note: `fromHex` and `compare` mimic the `Buffer.from('ff', 'hex')` and
`buf1.compare(buf2)` API. Their behavior should be the same in the browser
as well as in Node.

```js
import * as uint8arraytools from "uint8array-tools";
uint8arraytools.fromHex("ff");
// Uint8Array(1) [ 255 ]
uint8arraytools.toHex(Uint8Array.from([0xff]));
// 'ff'
uint8arraytools.compare(Uint8Array.from([0xff]), Uint8Array.from([0x01]));
// 1
uint8arraytools.compare(Uint8Array.from([0xff]), Uint8Array.from([0xff]));
// 0
uint8arraytools.compare(Uint8Array.from([0x01]), Uint8Array.from([0xff]));
// -1
uint8arraytools.fromUtf8("tools");
// Uint8Array(5) [ 116, 111, 111, 108, 115 ]
uint8arraytools.toUtf8(Uint8Array.from([116, 111, 111, 108, 115]));
// tools
uint8arraytools.concat([Uint8Array.from([1]), Uint8Array.from([2])]);
// Uint8Array(2) [ 1, 2 ]
uint8arraytools.fromBase64("dG9vbHM=");
// Uint8Array(3) [ 182, 138, 37 ]
uint8arraytools.toBase64(Uint8Array.from([116, 111, 111, 108, 115]));
// dG9vbHM=

const uint8array = new Uint8Array(2);
uint8arraytools.writeUInt16(uint8array, 0, 0xffff - 1, "LE");
uint8array;
// Uint8Array(2) [ 254, 255 ]
uint8arraytools.readUInt16(uint8array, 0, "LE");
// 65534
```
