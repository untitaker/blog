UNAME_S = $(shell uname)

SOUPAULT_VERSION = 4.4.0
HYPERLINK_VERSION = 0.1.25

ifeq ($(UNAME_S),Darwin)
	SOUPAULT_ARTIFACT_NAME = soupault-$(SOUPAULT_VERSION)-macos-x86_64
	HYPERLINK_ARTIFACT_NAME = hyperlink-mac-x86_64
	PANDOC_ARTIFACT_NAME = pandoc-2.19.2-macOS.zip
	PANDOC_EXTRACT_COMMAND = cat > tmp.zip && unzip tmp.zip pandoc-2.19.2/bin/pandoc -d $(PANDOC_ARTIFACT_NAME) && rm tmp.zip
else
	SOUPAULT_ARTIFACT_NAME = soupault-$(SOUPAULT_VERSION)-linux-x86_64
	HYPERLINK_ARTIFACT_NAME = hyperlink-linux-x86_64
	PANDOC_ARTIFACT_NAME = pandoc-2.19.2-linux-amd64.tar.gz
	PANDOC_EXTRACT_COMMAND = tar xz -C $(PANDOC_ARTIFACT_NAME)
endif

SOUPAULT_TARBALL_PATH = $(SOUPAULT_ARTIFACT_NAME)/soupault
PANDOC_TARBALL_PATH = $(SOUPAULT_ARTIFACT_NAME)/bin/pandoc
PYTHON = python3

pandoc:
	mkdir $(PANDOC_ARTIFACT_NAME)/
	curl -L https://github.com/jgm/pandoc/releases/download/2.19.2/$(PANDOC_ARTIFACT_NAME) | \
		$(PANDOC_EXTRACT_COMMAND)
	 mv $(PANDOC_ARTIFACT_NAME)/*/bin/pandoc .
	 rm -r $(PANDOC_ARTIFACT_NAME)

soupault:
	curl -L https://github.com/PataphysicalSociety/soupault/releases/download/$(SOUPAULT_VERSION)/$(SOUPAULT_ARTIFACT_NAME).tar.gz | \
		tar xz ./$(SOUPAULT_TARBALL_PATH)
	mv $(SOUPAULT_TARBALL_PATH) .
	rmdir $(SOUPAULT_ARTIFACT_NAME)

build: soupault pypi/bin/pygmentize pandoc
	rm -fr build/
	./soupault
.PHONY: build

linkcheck: build hyperlink
	./hyperlink build/
.PHONY: linkcheck

serve:
	cd build/ && $(PYTHON) -mhttp.server

watch:
	find site/ templates/ Makefile soupault.toml | entr $(MAKE) build linkcheck

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

pypi/bin/python:
	# https://www.youtube.com/watch?v=OXmYKh0eTQ8&list=PLWBKAf81pmOaP9naRiNAqug6EBnkPakvY
	curl https://bootstrap.pypa.io/virtualenv.pyz -o virtualenv.pyz
	$(PYTHON) virtualenv.pyz pypi/

pypi/bin/pygmentize:
	$(MAKE) pypi/bin/pygments

pypi/bin/%: pypi/bin/python
	pypi/bin/pip install $$(basename $@)

hyperlink:
	curl -L https://github.com/untitaker/hyperlink/releases/download/$(HYPERLINK_VERSION)/$(HYPERLINK_ARTIFACT_NAME) -o hyperlink
	chmod +x ./hyperlink

cloudflare-pages-build:
	$(MAKE) PYTHON=python3.7 build linkcheck
