#!/bin/bash

cd `dirname $0`

. ./common.sh

DRY_RUN=--dry-run
COMPACT=''

if [ "$1" = '--really' ]
then
	DRY_RUN=''
	COMPACT=--compact
fi

forget() {
	use_archive_repository
	echo forget files
	restic forget $DRY_RUN $COMPACT \
		--tag mysql \
		--tag postgresql \
		--tag files \
		--keep-daily 14 \
		--keep-weekly 5 \
		--keep-monthly 4
}

prune() {
	use_archive_repository
	restic prune
	test -n "$RESTIC_REPOSITORY" && restic prune
}

if [ "$1" = '--really' ]
then
	forget >$LOG
	egrep '^(forget|Applying|(keep|remove) [[:digit:]]+ snapshot)' $LOG
	prune
else
	forget
fi
