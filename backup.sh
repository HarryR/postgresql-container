#!/usr/bin/env bash

BACKUPTAR='backup.tar.xz'
BACKUPTARTMP=$BACKUPTAR.tmp

vagrant status | grep 'running'
OK=$?
if [[ $OK -eq 0 ]]; then
	echo "Error: vagrant box still running, cannot backup"
	exit $OK
fi

for FILE in data/*.vdi
do
	echo "Compacting $FILE"
	vboxmanage modifymedium $FILE --compact
done

tar -cJvpf "$BACKUPTARTMP" data/
mv "$BACKUPTARTMP" "$BACKUPTAR"
