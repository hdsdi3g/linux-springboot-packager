#!/bin/bash
#    cli-runner.bash - simply run a Java application as CLI
#    Linux Springboot Packager
#    https://github.com/hdsdi3g/linux-springboot-packager
#
#    Copyright (C) hdsdi3g for hd3g.tv 2023
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
#    Usage: run directly this script; all args will be passed on JVM.

set -eu

if ! [ -x "$(command -v java)" ]; then
    echo "Error: can't found java (JRE)" >&2
    exit 1;
fi

java -jar @OUTPUT_JAR_FILE@ "$@"
