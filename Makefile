INSTALL_DIR ?= $(HOME)/.local/bin
SCRIPT := mullvad-split-tunnel.sh
TARGET := $(INSTALL_DIR)/mullvad-split-tunnel

.PHONY: all install uninstall

all: install

install:
	@mkdir -p $(INSTALL_DIR)
	install -m 755 $(SCRIPT) $(TARGET)
	@CONFIG_DIR=$${XDG_CONFIG_HOME:-$$HOME/.config}/mullvad-split-tunnel; \
	  CONFIG_FILE=$$CONFIG_DIR/excluded-apps; \
	  mkdir -p $$CONFIG_DIR; \
	  if [ ! -f $$CONFIG_FILE ]; then \
	    : > $$CONFIG_FILE; \
	    echo "Created $$CONFIG_FILE"; \
	  else \
	    echo "Skipped config, $$CONFIG_FILE already exists"; \
	  fi
	@echo "Installed $(TARGET)"

uninstall:
	@rm -f $(TARGET)
	@echo "Removed $(TARGET)"
