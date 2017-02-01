#!/usr/bin/env bash

PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
  # Add PG apt repo:
  echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > "$PG_REPO_APT_SOURCE"

  # Add PGDG repo key:
  wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
fi

echo "unattended-upgrades       unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections

# Update package list and upgrade all packages
dpkg --configure -a
apt-get update
apt-get install -y unattended-upgrades
apt-get -y dist-upgrade

dpkg-reconfigure -f noninteractive unattended-upgrades

