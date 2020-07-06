#!/bin/bash

set -eu

cd "$(dirname "$0")"

if [ -d packages ]; then
	rm -rf packages
fi

if [ -d projects ]; then
	rm -rf projects
fi
