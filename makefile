

.PHONY: secp256r1

default: secp256r1

VERBOSE_LEVEL=-vv

secp256r1:
	rm src/include/*.sol; cp src/include/include_secp256r1/*.sol src/include;\
	forge test $(VERBOSE_LEVEL) --match-test=test_secp256r1 
babyjj:
	rm src/include/*.sol; cp src/include/include_babyjj/*.sol src/include;\
	forge test $(VERBOSE_LEVEL) --match-test=test_babyjj 
  
coverage:
	forge coverage  --report lcov && genhtml  lcov.info --branch-coverage --output-dir coverage   