INSTALL_DIR ?= $(HOME)/.local/bin
SCRIPT := mst.sh
TARGET := $(INSTALL_DIR)/mst

.PHONY: all install uninstall

all: install

install:
	@mkdir -p $(INSTALL_DIR)
	install -m 755 $(SCRIPT) $(TARGET)
	@CONFIG_DIR=$${XDG_CONFIG_HOME:-$$HOME/.config}/mst; \
	  CONFIG_FILE=$$CONFIG_DIR/excluded-apps.txt; \
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
	@CONFIG_DIR=$${XDG_CONFIG_HOME:-$$HOME/.config}/mst; \
	  CONFIG_FILE=$$CONFIG_DIR/excluded-apps.txt; \
	  if [ -f $$CONFIG_FILE ]; then \
		rm -rf $$CONFIG_DIR/; \
	    echo "Removed $$CONFIG_FILE"; \
	  else \
	    echo "Skipped removing config, $$CONFIG_FILE does not exist"; \
	  fi
	@echo "Removed $(TARGET)"
