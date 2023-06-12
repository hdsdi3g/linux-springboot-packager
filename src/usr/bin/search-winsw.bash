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
#    Or it will fail with an error message.
#
#    shellcheck disable=SC1090,SC1091

set -eu

PREFIX="${PREFIX:-"/"}";
. "$PREFIX/usr/lib/linux-springboot-packager/include/consts.bash"

declare -a POSSIBLE_PATHS=( "$HOME/.config/linux-springboot-packager" "$HOME/.bin" "$HOME/.local/bin" "$PREFIX/usr/bin" "$PREFIX/usr/lib/linux-springboot-packager/include" "$PREFIX/usr/lib/linux-springboot-packager/templates" )
declare -a POSSIBLE_NAMES=("WinSW.NET461.exe" "WinSW.NET4.exe" "WinSW.NET2.exe" "WinSW-x64.exe" "WinSW-x86.exe" )

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ ! -d "$path" ] ; then
        continue;
    fi
    for name in "${POSSIBLE_NAMES[@]}"; do
        if [ -f "$path/$name" ] ; then
            realpath "$path/$name";
            exit 0;
        fi
    done
done


echo "Can't found WinSW executable, please download it, and put it on ${POSSIBLE_PATHS[0]}".
mkdir -p "${POSSIBLE_PATHS[0]}";

exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
