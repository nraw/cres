PREFIX    ?= $(HOME)/.local
SHARE_DIR  = $(PREFIX)/share/cres
VERSION := $(shell cat VERSION)

.PHONY: all install uninstall test

all: test

test:
	@bash tests/test_extract.sh

install:
	@install -d $(SHARE_DIR)/shell
	@install -m644 shell/cres.sh shell/extract.jq $(SHARE_DIR)/shell/
	@install -m644 VERSION $(SHARE_DIR)/
	@printf '\n# cres\nexport CRES_DIR="%s/shell"\nsource "$$CRES_DIR/cres.sh"\n' \
		"$(SHARE_DIR)" >> $(or $(wildcard $(HOME)/.zshrc),$(HOME)/.bashrc)
	@echo "cres $(VERSION) installed to $(SHARE_DIR)"
	@echo "Restart your shell or: source ~/.zshrc"

uninstall:
	@rm -rf $(SHARE_DIR)
	@echo "Removed $(SHARE_DIR)"
	@echo "Remove the cres block from your shell rc manually."

help:
	@echo "Targets: install  uninstall  test"
