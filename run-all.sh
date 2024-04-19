#!/bin/bash

set -e -o pipefail

cd `dirname $0`

./run-mysql.sh
# ./run-postgresql.sh
./run-files.sh

./purge.sh --really
# ./push.sh
