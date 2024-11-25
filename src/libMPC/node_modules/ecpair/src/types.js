'use strict';
Object.defineProperty(exports, '__esModule', { value: true });
exports.maybe =
  exports.Boolean =
  exports.Array =
  exports.Buffer256bit =
  exports.Network =
  exports.typeforce =
    void 0;
exports.typeforce = require('typeforce');
// exposed, external API
exports.Network = exports.typeforce.compile({
  messagePrefix: exports.typeforce.oneOf(
    exports.typeforce.Buffer,
    exports.typeforce.String,
  ),
  bip32: {
    public: exports.typeforce.UInt32,
    private: exports.typeforce.UInt32,
  },
  pubKeyHash: exports.typeforce.UInt8,
  scriptHash: exports.typeforce.UInt8,
  wif: exports.typeforce.UInt8,
});
exports.Buffer256bit = exports.typeforce.BufferN(32);
exports.Array = exports.typeforce.Array;
exports.Boolean = exports.typeforce.Boolean; // tslint:disable-line variable-name
exports.maybe = exports.typeforce.maybe;
