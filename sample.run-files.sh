#!/bin/bash

cd `dirname $0`

. ./common.sh

TAG=files

use_archive_repository

restic backup \
	--tag "$TAG" \
	/where/the/important/files/are \
	--exclude "*.log"
