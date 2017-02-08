BACKUP_TODAY=$(shell date +%Y%m%d)
BACKUPS_DAILY=$(foreach N, 1 2 3 4 5 6 7,$(shell date +%Y%m%d -d "-$(N) day"))
BACKUPS_WEEKLY=$(foreach N, 0 1 2 3 4 5,$(shell date +%Y%m%d -d "sunday-$(N) week"))
BACKUP_FILES=$(sort $(addsuffix .tar.xz, $(BACKUP_TODAY) $(BACKUPS_DAILY) $(BACKUPS_WEEKLY)))

backup: backups backups/$(BACKUP_TODAY).tar.xz

backup-restart:
	vagrant halt
	make backup clean-backups
	vagrant up

install:
	vagrant plugin install vagrant-persistent-storage

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

all: up

vagrant-up:
	vagrant up

psql:
	PGUSER=$(shell cat data/conf/psql-user) PGPASSWORD=$(shell cat data/conf/psql-pass) psql -h localhost -p 5432 $(shell cat data/conf/psql-user)

xxx-destroy:
	vagrant destroy
	vboxmanage closemedium data/psql.vdi || true
	rm -rf data/psql.vdi data/conf .vagrant *.log
