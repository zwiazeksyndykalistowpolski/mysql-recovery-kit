help:
	@echo " >> make all				Clean up, build containers and run recovery"
	@echo " >> make all_without_build		Clean up, run the recovery (using container from docker hub)"
	@echo " >> make build_docker_image		Build docker image"
	@echo " >> make get_into_recovery_container	Get into the recovery container shell as root"
	@echo " >> make start				Start the recovery (without building container and doing cleanup)"
	@echo " >> make clean				Do a clean up"

all: clean build_docker_image start

all_without_build: clean start

build_docker_image:
	sudo docker build . -t wolnosciowiec/mysql-recovery-kit:bzr-trunk

get_into_recovery_container:
	sudo docker-compose exec db_recovery /bin/bash -c "cd /opt/percona* && /bin/bash"

start:
	sudo docker-compose rm
	sudo docker-compose up

clean:
	rm ./recovered/*.txt -f || true
	rm ./logs/*.log -f || true
	rm ./recovery-dumps/*.sql -f || true
