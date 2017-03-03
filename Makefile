CONF=data/conf

BACKUP_TODAY=$(shell date +%Y%m%d)
BACKUPS_DAILY=$(foreach N, 1 2 3 4 5 6 7,$(shell date +%Y%m%d -d "-$(N) day"))
BACKUPS_WEEKLY=$(foreach N, 0 1 2 3 4 5,$(shell date +%Y%m%d -d "sunday-$(N) week"))
BACKUP_FILES=$(sort $(addsuffix .tar.xz, $(BACKUP_TODAY) $(BACKUPS_DAILY) $(BACKUPS_WEEKLY)))

DOCKER_BASETAG=harryr/psql


all:
	@echo "make ..."
	@echo " - credentials"
	@echo " - psql"
	@echo " - vagrant-install"
	@echo " - vagrant-backup"
	@echo " - vagrant-up"
	@echo " - docker-psql"
	@echo " - docker-backup"
	@echo " - docker-run"
	@echo " - docker-stop"
	@echo " - docker-start"
	@echo " - restore"
	@echo " - xxx-destroy-data"


$(CONF):
	mkdir -p $(CONF)

$(CONF)/psql-db: $(CONF)
	if [ ! -f $@ ]; then basename `pwd` > $@ ; fi

$(CONF)/psql-user: $(CONF)
	if [ ! -f $@ ]; then openssl rand -base64 40 | tr -dc 'a-z' | cut -c 1-8 > $@; fi

$(CONF)/psql-pass: $(CONF)
	if [ ! -f $@ ]; then openssl rand -base64 40 | tr -dc 'a-zA-Z' | cut -c 1-15 > $@; fi

$(CONF)/env: $(CONF)/psql-pass $(CONF)/psql-user $(CONF)/psql-db
$(CONF)/env: TMPENV:=$(shell tempfile)
$(CONF)/env:
	echo '' > $(TMPENV)

	echo -n 'POSTGRES_USER=' >> $(TMPENV)
	cat $(CONF)/psql-user >> $(TMPENV)
	echo '' >> $(TMPENV)

	echo -n 'POSTGRES_DB=' >> $(TMPENV)
	cat $(CONF)/psql-db >> $(TMPENV)
	echo '' >> $(TMPENV)

	echo -n 'POSTGRES_PASSWORD=' >> $(TMPENV)
	cat $(CONF)/psql-pass >> $(TMPENV)
	echo '' >> $(TMPENV)

	mv -f $(TMPENV) $@


credentials: $(CONF)/psql-db $(CONF)/psql-user $(CONF)/psql-pass
	@echo "Database: `cat $(CONF)/psql-db`"
	@echo "Username: `cat $(CONF)/psql-user`"
	@echo "Password: `cat $(CONF)/psql-pass`"

backup: backups backups/$(BACKUP_TODAY).tar.xz

backups/$(BACKUP_TODAY).tar.xz: data/* data/conf/*
	tar -cJvpf $@.tmp data/
	mv $@.tmp $@

restore: backup.tar.xz
	tar -xf backup.tar.xz

backup.tar.xz:
	for FILE in `echo $(addprefix backups/,$(BACKUP_FILES)) | xargs -n 1 echo | sort -r`; do if [ -f $$FILE ]; then ln -s $$FILE backup.tar.xz; break; fi; done
 
.PHONY: trim-backups
trim-backups: 
	for FILE in $(filter-out $(addprefix backups/,$(BACKUP_FILES)), $(wildcard backups/*.tar.xz)); do rm $$FILE; done

psql:
	PGUSER=$(shell cat $(CONF)/psql-user) PGPASSWORD=$(shell cat $(CONF)/psql-pass) psql -h localhost -p 5432 $(shell cat $(CONF)/psql-db)


###############################################################

data/psql:
	mkdir -p data/psql

docker-build:
	docker build -t $(DOCKER_BASETAG) .

docker-stop:
	docker stop $(shell cat $(CONF)/psql-db)

docker-backup: docker-stop
	make backup trim-backups docker-start

docker-start:
	docker start $(shell cat $(CONF)/psql-db)

docker-run: $(CONF)/env data/psql
	docker run -d --name $(shell cat $(CONF)/psql-db) -h $(shell cat $(CONF)/psql-db) --env-file=$(CONF)/env -v `pwd`/data/psql:/var/lib/postgresql/data --restart=unless-stopped $(DOCKER_BASETAG)

docker-destroy:
	docker rm $(shell cat $(CONF)/psql-db) -f || true

docker-psql:
	docker exec -e PGUSER=$(shell cat $(CONF)/psql-user) -e PGPASSWORD=$(shell cat $(CONF)/psql-pass) -ti $(shell cat $(CONF)/psql-db) psql -h localhost -p 5432 $(shell cat $(CONF)/psql-db)

###############################################################


vagrant-backup:
	vagrant halt
	make backup trim-backups
	vagrant up

vagrant-install:
	vagrant plugin install vagrant-persistent-storage

vagrant-up:
	vagrant up

vagrant-destroy:
	vagrant destroy
	vboxmanage closemedium data/psql.vdi || true

xxx-destroy-data:
	rm -rf data/psql.vdi data/conf data/psql .vagrant *.log
