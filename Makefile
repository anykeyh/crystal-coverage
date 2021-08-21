CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN ?= $(shell which shards)
PREFIX ?= /usr/local
SHARD_BIN ?= ../../bin

build: bin/crystal-coverage
bin/crystal-coverage: $(shell find src -type f -name '*.cr')
	$(SHARDS_BIN) build $(CRFLAGS)
clean:
	rm -f .bin/crystal-coverage .bin/crystal-coverage.dwarf
install: build
	mkdir -p $(PREFIX)/bin
	cp ./bin/crystal-coverage $(PREFIX)/bin
bin: build
	mkdir -p $(SHARD_BIN)
	cp ./bin/crystal-coverage $(SHARD_BIN)
# test: build
# 	$(CRYSTAL_BIN) spec
# 	./bin/crystal-coverage
