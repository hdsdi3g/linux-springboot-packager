#!/bin/bash
# shellcheck disable=SC1090
#
# USAGE
# $0

set -eu

PWD=$(dirname "$0");
cd "$PWD"
SEARCH_DIR=$(cd .. && pwd);

. consts.bash

declare -a POSSIBLE_NAMES=("WinSW.NET461.exe" "WinSW.NET4.exe" "WinSW.NET2.exe" "WinSW-x64.exe" "WinSW-x86.exe" )

for name in ${POSSIBLE_NAMES[@]}; do
    if [ -f "$SEARCH_DIR/$name" ] ; then
        echo "$SEARCH_DIR/$name";
        exit 0;
    fi
done

echo "Can't found WinSW executable, please download it, and put it on $SEARCH_DIR".
exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
