build:
	liquidluck build

serve:
	liquidluck server

deploy:
	rsync -av --chmod=755 ./deploy/ untispace:~/virtual/unterwaditzer.net/


.PHONY: deploy serve build
