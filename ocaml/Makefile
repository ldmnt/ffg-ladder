DUNE = dune

outputs = ffg_ladder.exe stubs.bc.js

all: $(outputs)

ffg_ladder.exe:
	$(DUNE) build bin/ffg_ladder.exe

stubs.bc.js:
	$(DUNE) build stubs/stubs.bc.js

.PHONY: clean

clean:
	$(DUNE) clean
