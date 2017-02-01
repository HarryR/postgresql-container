#!/usr/bin/env bash

# Sometimes the installation steps may unmount the $MOUNTPATH
# However, after prodding it with fdisk, the LVM auto-mounter will kick in.

DEVPATH=/dev/sdc
MOUNTPATH=/var/lib/postgresql

while true;
do
    echo "*** Checking if persistent disk has mounted ***"
   	if [[ -d $MOUNTPATH/lost+found ]]; then
   		break
	fi
	echo "*** Probing and mounting ***"
	partprobe
	mount $MOUNTPATH
    sleep 1
done

echo "*** Success: $MOUNTPATH ***"