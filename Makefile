UNAME_S = $(shell uname)

ifeq ($(UNAME_S),Darwin)
	SOUPAULT_ARTIFACT_NAME = soupault-4.0.1-macos-x86_64
else
	SOUPAULT_ARTIFACT_NAME = soupault-4.0.1-linux-x86_64
endif

SOUPAULT_TARBALL_PATH = $(SOUPAULT_ARTIFACT_NAME)/soupault

soupault:
	curl https://files.baturin.org/software/soupault/4.0.1/$(SOUPAULT_ARTIFACT_NAME).tar.gz | \
		tar xz $(SOUPAULT_TARBALL_PATH)
	mv $(SOUPAULT_TARBALL_PATH) .
	rmdir $$(dirname $(SOUPAULT_TARBALL_PATH))

.venv/bin/python:
	rm -fr .venv
	virtualenv -ppython3 .venv
	.venv/bin/python -m pip install ghp-import

build: soupault
	rm -fr build/
	./soupault
.PHONY: build

linkcheck: build
	hyperlink build/
.PHONY: linkcheck

serve:
	cd build/ && python3 -mhttp.server

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

deploy: build linkcheck .venv/bin/python
	.venv/bin/ghp-import -pf build/
.PHONY: deploy
