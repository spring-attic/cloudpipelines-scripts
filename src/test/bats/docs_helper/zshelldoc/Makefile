NAME=zshelldoc

INSTALL?=install -c
PREFIX?=/usr/local
BIN_DIR?=$(DESTDIR)$(PREFIX)/bin
SHARE_DIR?=$(DESTDIR)$(PREFIX)/share/$(NAME)
DOC_DIR?=$(DESTDIR)$(PREFIX)/share/doc/$(NAME)

all: build/zsd build/zsd-transform build/zsd-detect build/zsd-to-adoc

build/zsd: src/zsd.preamble src/zsd.main
	mkdir -p build
	rm -f build/zsd
	cat src/zsd.preamble > build/zsd
	echo "" >> build/zsd
	cat src/zsd.main >> build/zsd
	chmod +x build/zsd

build/zsd-transform: src/zsd-transform.preamble src/zsd-transform.main src/zsd-process-buffer src/zsd-trim-indent
	mkdir -p build
	rm -f build/zsd-transform
	cat src/zsd-transform.preamble > build/zsd-transform
	echo "" >> build/zsd-transform
	echo "zsd-process-buffer() {" >> build/zsd-transform
	cat src/zsd-process-buffer >> build/zsd-transform
	echo "}" >> build/zsd-transform
	echo "" >> build/zsd-transform
	echo "zsd-trim-indent() {" >> build/zsd-transform
	cat src/zsd-trim-indent >> build/zsd-transform
	echo "}" >> build/zsd-transform
	echo "" >> build/zsd-transform
	cat src/token-types.mod >> build/zsd-transform
	echo "" >> build/zsd-transform
	cat src/zsd-transform.main >> build/zsd-transform
	chmod +x build/zsd-transform

build/zsd-detect: src/zsd-detect.preamble src/zsd-detect.main src/zsd-process-buffer src/run-tree-convert.mod src/token-types.mod
	mkdir -p build
	rm -f build/zsd-detect
	cat src/zsd-detect.preamble > build/zsd-detect
	echo "" >> build/zsd-detect
	echo "zsd-process-buffer() {" >> build/zsd-detect
	cat src/zsd-process-buffer >> build/zsd-detect
	echo "}" >> build/zsd-detect
	echo "" >> build/zsd-detect
	cat src/run-tree-convert.mod >> build/zsd-detect
	echo "" >> build/zsd-detect
	cat src/token-types.mod >> build/zsd-detect
	echo "" >> build/zsd-detect
	cat src/zsd-detect.main >> build/zsd-detect
	chmod +x build/zsd-detect

build/zsd-to-adoc: src/zsd-to-adoc.preamble src/zsd-to-adoc.main src/zsd-trim-indent
	mkdir -p build
	rm -f build/zsd-to-adoc
	cat src/zsd-to-adoc.preamble > build/zsd-to-adoc
	echo "" >> build/zsd-to-adoc
	echo "zsd-trim-indent() {" >> build/zsd-to-adoc
	cat src/zsd-trim-indent >> build/zsd-to-adoc
	echo "}" >> build/zsd-to-adoc
	echo "" >> build/zsd-to-adoc
	cat src/zsd-to-adoc.main >> build/zsd-to-adoc
	chmod +x build/zsd-to-adoc

install: build/zsd build/zsd-detect build/zsd-transform build/zsd-to-adoc
	$(INSTALL) -d $(SHARE_DIR)
	$(INSTALL) -d $(DOC_DIR)
	$(INSTALL) -d $(BIN_DIR)
	cp build/zsd build/zsd-transform build/zsd-detect build/zsd-to-adoc $(BIN_DIR)
	cp README.md NEWS LICENSE $(DOC_DIR)
	cp zsd.config $(SHARE_DIR)

uninstall:
	rm -f $(BIN_DIR)/zsd $(BIN_DIR)/zsd-transform $(BIN_DIR)/zsd-detect $(BIN_DIR)/zsd-to-adoc
	rm -f $(SHARE_DIR)/zsd.config $(DOC_DIR)/README.md $(DOC_DIR)/NEWS $(DOC_DIR)/LICENSE
	[ -d $(DOC_DIR) ] && rmdir $(DOC_DIR) || true
	[ -d $(SHARE_DIR) ] && rmdir $(SHARE_DIR) || true

clean:
	rm -rf build/*

test:
	make -C test test

.PHONY: all install uninstall test clean
