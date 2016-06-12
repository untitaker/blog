install:
	pip install liquidluck tornado

build:
	liquidluck build

serve:
	liquidluck server

open:
	xdg-open http://localhost:8000

deploy:
	rsync -av --delete --chmod=755 ./deploy/ untispace:~/virtual/unterwaditzer.net/


.PHONY: deploy serve build
