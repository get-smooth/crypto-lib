

.PHONY: secp256r1

default: secp256r1

VERBOSE_LEVEL=-vv

secp256r1:
	forge test $(VERBOSE_LEVEL) --match-test=test_secp256r1 

