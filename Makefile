install:
	pip install liquidluck tornado

build:
	rm -fr deploy
	liquidluck build

serve:
	liquidluck server

open:
	xdg-open http://localhost:8000

deploy:
	rsync -acv --delete --chmod=755 ./deploy/ unti@draco.uberspace.de:~/virtual/unterwaditzer.net/


.PHONY: deploy serve build
