#!/usr/bin/env bash

service snapd stop
systemctl disable snapd.service

service iscsid stop
systemctl disable iscsid.service

service lxcfs stop
systemctl disable lxcfs.service
