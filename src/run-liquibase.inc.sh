#!/bin/bash
#    run-liquibase.inc.sh - run Liquibase with a credentials configuration file
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
#    Usage: run it via a package setup ; it's just a template file.
#
#    shellcheck disable=SC1091,SC2154

if [ ! -x "$(command -v liquibase)" ]; then
    echo "Error: liquibase is not installed." >&2
    echo "Skip database update..." >&2;
    echo "See on man @SERVICE_NAME@ how-to run it manually." >&2;
elif [ ! -f "@OUTPUT_LIQUIBASECREDS_FILE@" ]; then
    echo "Can't found liquibase credentials in @OUTPUT_LIQUIBASECREDS_FILE@."
    echo "Please run sudo bash @OUTPUT_LIQUIBASESCRIPTCREDS_FILE@ for set it after.";
    echo "But for now, skip database update...";
    echo "More information on man @SERVICE_NAME@." >&2;
else
    echo "Start Liquibase automatic update for @NAME@...";
    . "@OUTPUT_LIQUIBASECREDS_FILE@";
    liquibase \
        --username="$dbusername" \
        --password="$dbuserpassword" \
        --url="$dburl" \
        --driver="$dbdriver" \
        --changeLogFile="@OUTPUT_LIQUIBASEXML_FILE@" \
        update
fi
