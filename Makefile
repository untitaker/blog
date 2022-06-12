SOUPAULT_TARBALL_PATH = soupault-4.0.1-linux-x86_64/soupault

soupault:
	curl https://files.baturin.org/software/soupault/4.0.1/soupault-4.0.1-linux-x86_64.tar.gz | \
		tar xz $(SOUPAULT_TARBALL_PATH)
	mv $(SOUPAULT_TARBALL_PATH) .
	rmdir $$(dirname $(SOUPAULT_TARBALL_PATH))

.venv/bin/python:
	rm -fr .venv
	virtualenv -ppython2 .venv
	.venv/bin/pip install ghp-import

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

deploy: build linkcheck .venv/bin/python
	.venv/bin/ghp-import -pf build/
.PHONY: deploy
