UNAME_S = $(shell uname)

SOUPAULT_VERSION = 4.11.0
HYPERLINK_VERSION = 0.1.40

ifeq ($(UNAME_S),Darwin)
	SOUPAULT_ARTIFACT_NAME = soupault-$(SOUPAULT_VERSION)-macos-x86_64
	HYPERLINK_ARTIFACT_NAME = hyperlink-x86_64-apple-darwin
	PANDOC_ARTIFACT_NAME = pandoc-2.19.2-macOS.zip
	PANDOC_EXTRACT_COMMAND = cat > tmp.zip && unzip tmp.zip pandoc-2.19.2/bin/pandoc -d $(PANDOC_ARTIFACT_NAME) && rm tmp.zip
else
	SOUPAULT_ARTIFACT_NAME = soupault-$(SOUPAULT_VERSION)-linux-x86_64
	HYPERLINK_ARTIFACT_NAME = hyperlink-x86_64-unknown-linux-gnu
	PANDOC_ARTIFACT_NAME = pandoc-2.19.2-linux-amd64.tar.gz
	PANDOC_EXTRACT_COMMAND = tar xz -C $(PANDOC_ARTIFACT_NAME)
endif

SOUPAULT_TARBALL_PATH = ./$(SOUPAULT_ARTIFACT_NAME)/soupault
HYPERLINK_TARBALL_PATH = $(HYPERLINK_ARTIFACT_NAME)/hyperlink
PYTHON = python3

bin/pandoc:
	mkdir $(PANDOC_ARTIFACT_NAME)/
	curl -L https://github.com/jgm/pandoc/releases/download/2.19.2/$(PANDOC_ARTIFACT_NAME) | \
		$(PANDOC_EXTRACT_COMMAND)
	 mv $(PANDOC_ARTIFACT_NAME)/*/bin/pandoc bin/
	 rm -r $(PANDOC_ARTIFACT_NAME)

bin/soupault:
	curl -L https://github.com/PataphysicalSociety/soupault/releases/download/$(SOUPAULT_VERSION)/$(SOUPAULT_ARTIFACT_NAME).tar.gz | \
		tar xz $(SOUPAULT_TARBALL_PATH)
	mv $(SOUPAULT_TARBALL_PATH) bin/
	rmdir $(SOUPAULT_ARTIFACT_NAME)

build: bin/soupault bin/pandoc
	rm -rf build/
	./bin/soupault
.PHONY: build

linkcheck: build bin/hyperlink
	./bin/hyperlink build/
.PHONY: linkcheck

linkcheck-ext: build bin/hyperlink
	hyperlink dump-external-links build/ | \
		rg '^https?://' | \
		rg -v '^http://developers.flattr.net/auto-submit/' | \
		rg -v '^https://docs.rsshub.app/' | \
		rg -v '^https://twitter.com/' | \
		rg -v '^https://crates.io/' | \
		rg -v '^https://gts.woodland.cafe/@untitaker' | \
		xargs -P20 -I{} bash -c 'curl -ILf "{}" &> /dev/null || (echo "{}" && exit 1)'
.PHONY: linkcheck-ext

serve:
	$(PYTHON) -mhttp.server -d build/

watch:
	find site/ templates/ scripts/ Makefile soupault.toml | entr $(MAKE) build linkcheck

open:
	open http://localhost:8000 || xdg-open http://localhost:8000

dev:
	$(MAKE) -j3 serve watch open

html-diff:
	rm -rf build-old
	mkdir -p build-old
	git stash
	$(MAKE) build
	cp -R build/* build-old/
	cd build-old && git init && git add -A && git commit -am 'init'
	git stash pop
	$(MAKE) build
	cp -R build/* build-old/
	cd build-old && git diff
.PHONY: html-diff

bin/hyperlink:
	curl -L https://github.com/untitaker/hyperlink/releases/download/$(HYPERLINK_VERSION)/$(HYPERLINK_ARTIFACT_NAME).tar.xz | tar x -J $(HYPERLINK_TARBALL_PATH)
	mv $(HYPERLINK_TARBALL_PATH) bin/
	rmdir $(HYPERLINK_ARTIFACT_NAME)
	chmod +x ./bin/hyperlink
