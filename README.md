# PostgreSQL 9.5 in a Vagrant Box

Creates a Vagrant box containing PostgreSQL 9.5.

A random schema name, login and password are chosen when provisioned, details are displayed on the console.

    vagrant up
    make psql  # Connect to PostgreSQL console

Daily and weekly backups for the past month are kept in the `backups` directory, add a cron job to perform the backup:

    @daily vagrant halt; make backup clean-backups; vagrant up

Restore from the latest snapshot is possible, but is broken if you destroy the machine.

    make restore 

To destroy the box, and all runtime data, but will not delete backups:

    make xxx-destroy

Requires Vagrant plugins and GNU Make:

    vagrant plugin install vagrant-persistent-storage

