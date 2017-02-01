all: up

up:
	vagrant up

psql:
	PGUSER=$(shell cat data/conf/psql-user) PGPASSWORD=$(shell cat data/conf/psql-pass) psql -h localhost -p 5432 $(shell cat data/conf/psql-user)

xxx-destroy:
	vagrant destroy
	rm -rf data .vagrant
