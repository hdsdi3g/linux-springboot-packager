#!/bin/bash

set -eu

export SKIP_LIQUIBASE=1

"$(dirname "$0")/extract-all.bash" 1
