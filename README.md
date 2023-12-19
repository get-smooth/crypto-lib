# SmoothCryptoLib
A Cryptographic Library for Smooth Blockchain uses


## Compilation

SmoothCryptoLib aims at providing any ECC library. To optimize the performances, while avoiding code duplication, a "heading" system is used to configure the library for a specific curve. To configure the library, the right include directory shall be pasted into /include.

For instance to configure the library for the secp256r1, one shall paste /include_secp256r1 into /include.

The configuration is performed by the makefile:
 * make secp256r1 : configure the library for the secp256r1/P256 file

For this reason a direct call to forge test will fail, as it will run tests for all curves. Tests are performed when using the makefile, which uses the 
--match-test= from forge.
