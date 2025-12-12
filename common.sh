set -e -E -o pipefail

err_exit() {
	echo "$0: exit with error on line $1" >&2
}

trap 'err_exit $LINENO' ERR

# Prefer fixed env path for cron/systemd reliability
if [ -f /etc/restic/env ]; then
    . /etc/restic/env
elif [ -f "$HOME/.env.restic" ]; then
    . "$HOME/.env.restic"
fi

if [ -z "$LOGNAME" ]
then
	echo LOGNAME must contain the username
	exit 2
fi

if [ -z "$RESTIC_REPOSITORY" -a -z "$RESTIC_ARCHIVE_REPOSITORY" ]
then
	echo one of RESTIC_REPOSITORY and RESTIC_ARCHIVE_REPOSITORY
	echo must specify the restic repository.
	exit 2
fi

if [ -z "$RESTIC_PASSWORD_FILE" ]
then
	echo RESTIC_PASSWORD_FILE must specify the restic repository password.
	exit 2
fi

use_archive_repository() {
	if [ -n "$RESTIC_ARCHIVE_REPOSITORY" ]
	then
		export RESTIC_REPOSITORY=$RESTIC_ARCHIVE_REPOSITORY
	fi
}

[ -d "log" ] || mkdir log

LOG="log/$(basename $0)-$(date +%Y-%m-%d).log"
