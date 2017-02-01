#!/usr/bin/env bash
DEVPATH=/dev/sdc1
MOUNTPATH=/var/lib/postgresql
while true;
do
    echo "*** Checking if persistent disk has mounted ***"
	fdisk -l $DEVPATH &> /dev/null
	OK=$?
	if [[ $OK -eq 0 ]]; then
	    mount | grep $MOUNTPATH &> /dev/null
	    OK=$?
	    if [[ $OK -eq 0 ]]; then
	        break
	    fi
	    echo "*** Cannot find mountpoint ***"
	else
		echo "*** Cannot find disk ***"
    fi

    sleep 1
done
echo "*** Success: $DEVPATH mounted at $MOUNTPATH ***"