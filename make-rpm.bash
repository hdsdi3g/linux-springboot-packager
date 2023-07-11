#!/bin/bash
#    make-rpm.bash - create a RPM package file for linux-springboot-packager
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
#    Usage: make-rpm.bash
#
#    You will need git, realpath, man, pandoc, rpmlint, rpmbuild, rpm
#    Fonctionnal on Debian-like hosts.

set -eu

# PREPARE VARS AND PATHS

ROOT=$(realpath "$(dirname "$0")");
SOURCE_DIR="$ROOT/src";

VERSION=$(git describe --tags | sed 's/-/_/g');
export VERSION;

RELEASE=$(LANG="en_US.UTF-8" date '+%Y%m%d%H%M%S');
export RELEASE;

# CREATE RPM

BUILDROOT="$ROOT/rpmbuild/BUILDROOT";
if [ -d "$BUILDROOT" ]; then
    rm -rf "$BUILDROOT";
fi
cp -r "$SOURCE_DIR" "$BUILDROOT";

RPMS="$ROOT/rpmbuild/RPMS";
if [ -d "$RPMS" ]; then
    rm -rf "$RPMS";
fi

# PREPARE MAN

MAN_DIR="$BUILDROOT/usr/local/share/man/man1";
mkdir -p "$MAN_DIR"
pandoc -s -t man -o "$MAN_DIR/make-springboot-rpm.1" "$ROOT/man-make-springboot-rpm.md"
pandoc -s -t man -o "$MAN_DIR/make-springboot-exe.1" "$ROOT/man-make-springboot-exe.md"
pandoc -s -t man -o "$MAN_DIR/search-winsw.bash.1" "$ROOT/search-winsw.bash.md"

SPEC_FILE="rpmbuild/SPECS/rpm-centos.spec";
rpmlint "$SPEC_FILE"
rpmbuild --define "_libdir /usr/lib" -bb "$SPEC_FILE"

if [ -d "$BUILDROOT" ]; then
    rm -rf "$BUILDROOT";
fi

# CHECK BUILDED RPM

RPMS_FILE=$(find "$RPMS" -type f -name "*.rpm");
rpm -qi "$RPMS_FILE";
echo "";
echo "Now, you can install this app with sudo rpm -U $RPMS_FILE";
