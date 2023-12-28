This directory contains code intended to prove the full coverage of function used elsewhere either because:
* as of 26/12/2023 forge coverage is not able to cover loop of asm instructions
* as of 26/12/2023 forge coverage doesn't provide coverage for 'free functions' (function not in a library or contract)

As example, the ecMulmulAdd function is both a free function, including a complex asm loop not rendered by forge coverage.