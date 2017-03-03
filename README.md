# PostgreSQL 9.5 container with daily backups

Creates a container for PostgreSQL 9.5 for Vagrant+VirtualBox or Docker which takes nightly backups.

The database name will be the name of the directory you checkout the repository into, to create a database called 'myapp-db' run:

    git clone https://github.com/HarryR/vagrant-psql.git myapp-db

To get started with Docker, run:

	make docker-build docker-start docker-psql

To get started with Vagrant, run:

	make vagrant-install vagrant-up

A random login and password are chosen when provisioned, these are stored in the `data/conf` directory, run `make credentials` to display them.

## Backups

Daily backups are made for a week, and then each sundays backups for a month are kept in the `backups` directory, to setup backups add a cron job for the container type you chose:

    @daily make -C /path-to/this-dir/ vagrant-backup
    @daily make -C /path-to/this-dir/ docker-backup

Each Sunday's backups will be kept, and the past 7 days will be kept, resulting in files like:

 * `backups/20161203.tar.xz`
 * `backups/20161210.tar.xz`
 * `backups/20161217.tar.xz`
 * `backups/20161218.tar.xz`
 * `backups/20161219.tar.xz`
 * `backups/20161220.tar.xz`
 * `backups/20161221.tar.xz`
 * `backups/20161222.tar.xz`
 * `backups/20161223.tar.xz`

You cannot restore the data from a Docker container into a Vagrant instance or visa versa. What you do with the backups is your business, but I suggest encrypting and uploading to the cloud with [transfer.py](https://github.com/0x27/transfer.py).

Restore from the latest available snapshot is possible, put the .tar.xz file into the `backups/` directory and run:

    make restore

## Misc

To destroy the box, and all runtime data, but will not delete backups:

    make xxx-destroy-data

To automatically start a Vagrant container at boot, use:

    @reboot make -C /path-to/this-dir/ vagrant-up
