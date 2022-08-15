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

build: soupault pypi/bin/pygmentize
	rm -fr build/
	PYTHONPATH=$$(echo pypi/lib/*/site-packages/) ./soupault
.PHONY: build

linkcheck: build crates/bin/hyperlink
	crates/bin/hyperlink build/
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

deploy: build linkcheck crates/bin/ghp
	crates/bin/ghp build
	git push -f origin gh-pages
.PHONY: deploy

crates/bin/%:
	cargo install --root $$(pwd)/crates/ $$(basename $@/)

pypi/bin/pygmentize:
	$(MAKE) pypi/bin/pygments

pypi/bin/%:
	python3 -m pip install --system --isolated -I --root . --prefix pypi $$(basename $@)
