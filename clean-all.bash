#!/bin/bash

set -eu

cd "$(dirname "$0")"

if [ -d exebuild ]; then
	rm -rf exebuild
fi

if [ -d rpmbuild ]; then
	rm -rf rpmbuild
fi
