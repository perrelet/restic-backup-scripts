#!/bin/bash

set -e -o pipefail

cd `dirname $0`

restic unlock >/dev/null 2>&1 || true

./run-mysql.sh
# ./run-postgresql.sh
./run-files.sh

./purge.sh --really
# ./push.sh
