#!/bin/bash
#    search-winsw.bash - search the full path of WinSW executable
#
#    Copyright (C) hdsdi3g for hd3g.tv 2022
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or any
#    later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <https://www.gnu.org/licenses/>.
#
#    Usage: search-winsw.bash
#    It will return the full path of WinSW executable.
#    Or it will fail with a error message.
#
#    shellcheck disable=SC1090,SC1091

set -eu

PWD=$(dirname "$0");
cd "$PWD"
SEARCH_DIR=$(cd .. && pwd);

. consts.bash

declare -a POSSIBLE_NAMES=("WinSW.NET461.exe" "WinSW.NET4.exe" "WinSW.NET2.exe" "WinSW-x64.exe" "WinSW-x86.exe" )

for name in "${POSSIBLE_NAMES[@]}"; do
    if [ -f "$SEARCH_DIR/$name" ] ; then
        echo "$SEARCH_DIR/$name";
        exit 0;
    fi
done

echo "Can't found WinSW executable, please download it, and put it on $SEARCH_DIR".
exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
