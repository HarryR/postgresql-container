# PostgreSQL 9.5 in a Vagrant Box

Creates a Vagrant box containing PostgreSQL 9.5.

A random schema name, login and password are chosen when provisioned, details are displayed on the console.

    vagrant up
    make psql  # Connect to PostgreSQL console

To destroy the box, and all data:

    make xxx-destroy

Requires Vagrant plugins:

    vagrant plugin install vagrant-persistent-storage

