import * as tools from 'uint8array-tools';
export function makeConverter(TYPE_BYTE) {
  function decode(keyVal) {
    if (keyVal.key[0] !== TYPE_BYTE) {
      throw new Error(
        'Decode Error: could not decode redeemScript with key 0x' +
          tools.toHex(keyVal.key),
      );
    }
    return keyVal.value;
  }
  function encode(data) {
    const key = Uint8Array.from([TYPE_BYTE]);
    return {
      key,
      value: data,
    };
  }
  const expected = 'Uint8Array';
  function check(data) {
    return data instanceof Uint8Array;
  }
  function canAdd(currentData, newData) {
    return !!currentData && !!newData && currentData.redeemScript === undefined;
  }
  return {
    decode,
    encode,
    check,
    expected,
    canAdd,
  };
}
