#!/bin/bash
#    create-user.inc.sh - create an Linux user based on SERVICE_USER_NAME variable.
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

# CREATE USER ONLY IF NOT EXISTS

USER_EXISTS=$(id -u "@SERVICE_USER_NAME@" > /dev/null 2>&1; echo $?);
if [ "$USER_EXISTS" -gt "0" ]; then
    echo "Create group @SERVICE_USER_NAME@"
    groupadd -r "@SERVICE_USER_NAME@"
    echo "Create user @SERVICE_USER_NAME@";
    useradd -d "@USER_HOME_DIR@" -m -g "@SERVICE_USER_NAME@" -r -s /bin/false "@SERVICE_USER_NAME@"
fi
