.venv/bin/python:
	rm -fr .venv
	virtualenv -ppython2 .venv
	.venv/bin/pip install liquidluck tornado ghp-import

build: .venv/bin/python
	rm -fr deploy
	.venv/bin/liquidluck build
.PHONY: build

serve: build
	.venv/bin/liquidluck server
.PHONY: serve

open: serve
	xdg-open http://localhost:8000
.PHONY: open

deploy: build
	.venv/bin/ghp-import -pf deploy/

deploy-legacy: build
	rsync -acv --delete --chmod=755 ./deploy/ unti@draco.uberspace.de:~/virtual/unterwaditzer.net/
.PHONY: deploy
