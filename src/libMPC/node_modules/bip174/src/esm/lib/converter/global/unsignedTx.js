import { GlobalTypes } from '../../typeFields.js';
export function encode(data) {
  return {
    key: new Uint8Array([GlobalTypes.UNSIGNED_TX]),
    value: data.toBuffer(),
  };
}
