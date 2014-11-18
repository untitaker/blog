build:
	liquidluck build

serve:
	liquidluck server

deploy:
	rsync --del -rvze ssh ./deploy/ untispace:~/virtual/unterwaditzer.net/

.PHONY: deploy serve build
