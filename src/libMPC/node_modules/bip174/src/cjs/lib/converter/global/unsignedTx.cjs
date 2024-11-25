'use strict';
Object.defineProperty(exports, '__esModule', { value: true });
const typeFields_js_1 = require('../../typeFields.cjs');
function encode(data) {
  return {
    key: new Uint8Array([typeFields_js_1.GlobalTypes.UNSIGNED_TX]),
    value: data.toBuffer(),
  };
}
exports.encode = encode;
