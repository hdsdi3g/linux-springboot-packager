#!/bin/bash
#    get-last-release.bash - find, download and install the last linux-springboot-packager from GitHub repo.
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
#    Usage: ./get-last-release.bash
#

set -eu

REPO_URL="https://github.com/hdsdi3g/linux-springboot-packager";
PACKAGE_NAME="linux-springboot-packager";

function check_deps() {
    if ! [ -x "$(command -v "$1")" ]; then
        echo "Error: $1 is not installed." >&2
        exit 1;
    fi
}
check_deps curl;
check_deps rev;
check_deps cut;

LAST_RELEASE_TAG=$(curl -LsI -o /dev/null -w "%{url_effective}" "$REPO_URL/releases/latest" | rev | cut -d "/" -f 1 | rev);
echo "Last release: $LAST_RELEASE_TAG";

if [ -x "$(command -v yum)" ] || [ -x "$(command -v dnf)" ]; then
    check_deps rpm;
    PACKAGE_TYPE="rpm";
    SETUP_COMMAND="rpm -U";
fi
if [ -x "$(command -v apt-get)" ]; then
    check_deps dpkg;
    PACKAGE_TYPE="deb";
    SETUP_COMMAND="dpkg -i";
fi

if ! [[ -v PACKAGE_TYPE ]]; then
    echo "Can't detect OS type (rpm or deb type)";
    exit 1;
fi
echo "Package type: $PACKAGE_TYPE";

PACKAGE_FILE_NAME="$PACKAGE_NAME-$LAST_RELEASE_TAG.$PACKAGE_TYPE";
echo "Download $PACKAGE_FILE_NAME";

curl -L "$REPO_URL/releases/download/$LAST_RELEASE_TAG/$PACKAGE_FILE_NAME" > "$PACKAGE_FILE_NAME";

ROOT_PREFIX="";
if [ "$EUID" -ne 0 ]; then
    check_deps sudo;
    ROOT_PREFIX="sudo ";
fi

FULL_CMD="$ROOT_PREFIX$SETUP_COMMAND $PACKAGE_FILE_NAME";
echo "Run $FULL_CMD"
$FULL_CMD

exit 0;
