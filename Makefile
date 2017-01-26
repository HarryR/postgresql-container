all:
	@echo "Bleh"

psql:
	PGUSER=UJzUdjVgnCiGk PGPASSWORD=VAcTTtsbQPwqrt psql -h localhost -p 5432 UJzUdjVgnCiGk

xxx-destroy:
	vagrant destroy
	rm -rf data .vagrant