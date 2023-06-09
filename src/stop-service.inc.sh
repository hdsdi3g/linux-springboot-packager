#!/bin/bash
#    stop-service.inc.sh - stop systemctl service based on SERVICE_NAME variable.
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

COUNT_SERVICE_PRESENCE=$(systemctl list-unit-files | grep -c @SERVICE_NAME@);
if [ "$COUNT_SERVICE_PRESENCE" -gt "0" ]; then
    RUNNING_SERVICE=$(systemctl is-active --quiet @SERVICE_NAME@ > /dev/null 2>&1; echo $?);
    if [ "$RUNNING_SERVICE" -eq "0" ]; then
        echo "Service @SERVICE_NAME@ is running: stop it.";
        systemctl stop "@SERVICE_NAME@"
    fi
fi
