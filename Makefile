.venv/bin/python:
	rm -fr .venv
	virtualenv -ppython2 .venv
	.venv/bin/pip install liquidluck tornado

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
	rsync -acv --delete --chmod=755 ./deploy/ unti@draco.uberspace.de:~/virtual/unterwaditzer.net/
.PHONY: deploy
