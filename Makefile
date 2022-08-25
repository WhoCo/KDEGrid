PROJECT_NAME = kdegrid
PROJECT_VER  = 0.7.3
PROJECT_REV  = $(shell git rev-parse HEAD | cut -b-7)

BUILD_DIR = build

KWINPKG_FILE = $(PROJECT_NAME)-$(PROJECT_VER)-$(PROJECT_REV).kwinscript
KWINPKG_DIR = build/pkg

DIST_DIR = dist
DIST_FILE = $(DIST_DIR)/$(KWINPKG_FILE)

KWIN_META   = $(KWINPKG_DIR)/metadata.desktop
KWIN_MAIN_QML    = $(KWINPKG_DIR)/contents/ui/main.qml
KWIN_OVERLAY_QML    = $(KWINPKG_DIR)/contents/ui/overlay.qml
KWIN_RES_DIR    = $(KWINPKG_DIR)/contents/res
KWIN_RES_TRAY_ICON    = $(KWIN_RES_DIR)/tray.png

NODE_SCRIPT = build/obj/main.js
NODE_META   = package.json
NODE_FILES  = $(NODE_SCRIPT) package-lock.json

SRC = $(shell find src -name "*.ts")

all: clean $(KWINPKG_DIR) package

clean:
	@rm -rvf $(KWINPKG_DIR) $(DIST_DIR) $(BUILD_DIR)
	@rm -vf $(NODE_FILES)

install: package
	plasmapkg2 -t kwinscript -s $(PROJECT_NAME) \
		&& plasmapkg2 -u $(KWINPKG_FILE) \
		|| plasmapkg2 -i $(KWINPKG_FILE)
		
uninstall:
	plasmapkg2 -t kwinscript -r $(PROJECT_NAME)

package: $(DIST_FILE)

test: $(NODE_SCRIPT) $(NODE_META)
	npm test

stop:
	bin/load-script.sh "unload" "$(PROJECT_NAME)-test"

$(DIST_FILE): $(KWINPKG_DIR)
	@mkdir -vp $(DIST_DIR)
	@rm -f "$(DIST_FILE)"
	@7z a -tzip $(DIST_FILE) ./$(KWINPKG_DIR)/*

$(KWINPKG_DIR): $(KWIN_META)
$(KWINPKG_DIR): $(KWIN_MAIN_QML)
$(KWINPKG_DIR): $(KWIN_OVERLAY_QML)
$(KWINPKG_DIR): $(KWIN_RES_TRAY_ICON)
$(KWINPKG_DIR): $(KWINPKG_DIR)/contents/ui/config.ui
$(KWINPKG_DIR): $(KWINPKG_DIR)/contents/code/main.js
$(KWINPKG_DIR): $(KWINPKG_DIR)/contents/config/main.xml
	@touch $@

$(KWIN_META): res/metadata.desktop
	@mkdir -vp `dirname $(KWIN_META)`
	@sed "s/\$$VER/$(PROJECT_VER)/" $< \
		| sed "s/\$$REV/$(PROJECT_REV)/" \
		> $(KWIN_META)

$(KWIN_MAIN_QML): src/ui/main.qml
$(KWIN_OVERLAY_QML): src/ui/overlay.qml
$(KWIN_RES_TRAY_ICON): res/tray.png
$(KWINPKG_DIR)/contents/ui/config.ui: src/ui/config.ui
$(KWINPKG_DIR)/contents/code/main.js: $(NODE_SCRIPT)
$(KWINPKG_DIR)/contents/config/main.xml: src/config/main.xml
$(KWINPKG_DIR)/%:
	@mkdir -vp `dirname $@`
	@cp -v $< $@

$(NODE_SCRIPT): $(SRC)
	@tsc

$(NODE_META): package.json
	@sed "s/\$$VER/$(PROJECT_VER).0/" $< > $@

.PHONY: all clean install package test run stop
