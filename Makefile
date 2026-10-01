shell:
	docker exec -it -e "TERM=xterm-256color" buildbot su vagrant

rootshell:
	docker exec -it buildbot bash

teardown:
	docker stop buildbot
	docker rm buildbot

image:
	mkdir -p /tmp/buildbot
	cp -v setup-buildbot.sh /tmp/buildbot
	cp -v Dockerfile /tmp/buildbot
	cd /tmp/buildbot
	docker build -t gamey_camper:lutris-buildbot .

setup:
	mkdir -p builds
	docker create --interactive --name buildbot \
		--mount type=bind,source="$$PWD"/builds,destination=/builds,readonly=false \
		--mount type=bind,source="$$PWD",destination=/home/vagrant/buildbot,readonly=false \
		gamey_camper:lutris-buildbot
	docker start buildbot

