CONF=data/conf

BACKUP_TODAY=$(shell date +%Y%m%d)
BACKUPS_DAILY=$(foreach N, 1 2 3 4 5 6 7,$(shell date +%Y%m%d -d "-$(N) day"))
BACKUPS_WEEKLY=$(foreach N, 0 1 2 3 4 5,$(shell date +%Y%m%d -d "sunday-$(N) week"))
BACKUP_FILES=$(sort $(addsuffix .tar.xz, $(BACKUP_TODAY) $(BACKUPS_DAILY) $(BACKUPS_WEEKLY)))

DOCKER_BASETAG=harryr/psql


all:
	@echo "?"


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


backup: backups backups/$(BACKUP_TODAY).tar.xz

backups/$(BACKUP_TODAY).tar.xz: data/* data/conf/*
	tar -cJvpf $@.tmp data/
	mv $@.tmp $@

restore: backup.tar.xz
	tar -xf backup.tar.xz

backup.tar.xz:
	for FILE in `echo $(addprefix backups/,$(BACKUP_FILES)) | xargs -n 1 echo | sort -r`; do if [ -f $$FILE ]; then ln -s $$FILE backup.tar.xz; break; fi; done
 
.PHONY: clean-backups
clean-backups: 
	for FILE in $(filter-out $(addprefix backups/,$(BACKUP_FILES)), $(wildcard backups/*.tar.xz)); do rm $$FILE; done

psql:
	PGUSER=$(shell cat data/conf/psql-user) PGPASSWORD=$(shell cat data/conf/psql-pass) psql -h localhost -p 5432 $(shell cat data/conf/psql-db)


###############################################################

data/psql:
	mkdir -p data/psql

docker-build:
	docker build -t $(DOCKER_BASETAG) .

docker-stop:
	docker stop psql

docker-backup: docker-stop
	make backup clean-backups docker-start

docker-start:
	docker start psql

docker-create: $(CONF)/env data/psql
	docker run --name psql -h psql -p 5432:5432 --env-file=$(CONF)/env -v `pwd`/data/psql:/var/lib/postgresql/data $(DOCKER_BASETAG)

docker-destroy:
	docker rm psql -f || true


###############################################################


vagrant-backup:
	vagrant halt
	make backup clean-backups
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
