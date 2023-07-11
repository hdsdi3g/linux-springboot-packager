#!/bin/bash
#    disable-service.inc.sh - disable systemctl service based on SERVICE_NAME variable.
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
#    With RPM parameters:
#    0 remove
#    1 install
#    1 upgrade old uninstall
#    2 upgrade new install

if [ "$1" -eq "0" ]; then
    # 0 remove
    COUNT_SERVICE_ENABLED=$(systemctl list-unit-files --state=enabled | grep -c @SERVICE_NAME@);
    if [ "$COUNT_SERVICE_ENABLED" -gt "0" ]; then
        echo "Service @SERVICE_NAME@ is enabled: disable it.";
        systemctl disable "@SERVICE_NAME@"
    fi
fi
