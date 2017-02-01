#!/usr/bin/env bash

DATA_ROOT=/var/lib/postgresql
CONF_ROOT=/opt/psql-conf
CONF_USER_FILE="$CONF_ROOT/psql-user"
CONF_PASS_FILE="$CONF_ROOT/psql-pass"

# Since Vagrant 1.8.x you can override environment variables with:
# config.vm.provision "shell", path: "provisionscript.sh", env: {"MYVAR" => "value"}

# If these aren't specified in Vagrantfile, then random ones will be decided

if [[ -z $APP_DB_USER ]]; then
  if [[ ! -f "$CONF_USER_FILE" ]]; then
    openssl rand -base64 12 | tr -dc 'a-z' > "$CONF_USER_FILE"
  fi
  APP_DB_USER=`cat $CONF_USER_FILE`
fi

if [[ -z $APP_DB_PASS ]]; then
  if [[ ! -f "$CONF_PASS_FILE" ]]; then
    openssl rand -base64 12 | tr -dc 'a-zA-Z' > "$CONF_PASS_FILE"
  fi
  APP_DB_PASS=`cat $CONF_PASS_FILE`
fi

# Edit the following to change the name of the database that is created (defaults to the user name)
if [[ -z $APP_DB_NAME ]]; then
  APP_DB_NAME=$APP_DB_USER
fi

# Edit the following to change the version of PostgreSQL that is installed
if [[ -z $PG_VERSION ]]; then
  PG_VERSION=9.5
fi

###########################################################
# Changes below this line are probably not necessary
###########################################################
print_db_usage () {
  echo "Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: 15432)"
  echo "  Host: localhost"
  echo "  Port: 5432"
  echo "  Database: $APP_DB_NAME"
  echo "  Username: $APP_DB_USER"
  echo "  Password: $APP_DB_PASS"
  echo ""
  echo "Admin access to postgres user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo ""
  echo "psql access to app database user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME"
  echo ""
  echo "Env variable for application development:"
  echo "  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:5432/$APP_DB_NAME"
  echo ""
  echo "Local command to access the database via psql:"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 5432 $APP_DB_NAME"
}

export DEBIAN_FRONTEND=noninteractive

PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
  echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
  echo "To run system updates manually login via 'vagrant ssh' and run 'apt-get update && apt-get upgrade'"
  echo ""
  print_db_usage
  exit
fi

PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
  # Add PG apt repo:
  echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > "$PG_REPO_APT_SOURCE"

  # Add PGDG repo key:
  wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
fi

# Update package list and upgrade all packages
dpkg --configure -a
# apt-get purge -y snapd lxcfs lxc-common lxd lxd-client open-iscsi
apt-get update
# apt-get -y dist-upgrade

apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"

# apt-get autoremove --purge -y

PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main"

# Edit postgresql.conf to change listen address to '*':
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Append to pg_hba.conf to add password auth:
echo "host    all             all             all                     md5" >> "$PG_HBA"

# Explicitly set default client_encoding
echo "client_encoding = utf8" >> "$PG_CONF"

# Restart so that all new config is loaded:
service postgresql restart

cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';

-- Create the database:
CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER
                                  LC_COLLATE='en_US.UTF-8'
                                  LC_CTYPE='en_US.UTF-8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
GRANT ALL PRIVILEGES ON DATABASE $APP_DB_NAME TO $APP_DB_USER;
EOF

# Tag the provision time:
date > "$PROVISIONED_ON"

echo "Successfully created PostgreSQL dev virtual machine."
echo ""
print_db_usage