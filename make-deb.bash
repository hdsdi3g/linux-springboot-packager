#!/bin/bash
#    make-deb.bash - create a DEB package file for linux-springboot-packager
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
#    Usage: make-deb.bash
#
#    You will need git, realpath, man, pandoc, dpkg-deb and lintian
#    Fonctionnal on Debian-like hosts.

set -eu

# PREPARE VARS AND PATHS

ROOT=$(realpath "$(dirname "$0")");
SOURCE_DIR="$ROOT/src";

# PREPARE DEB
PKGDEB_DIR="$ROOT/pkgdeb";
if [ -d "$PKGDEB_DIR" ]; then
    rm -rf "$PKGDEB_DIR"
fi
cp -r "$SOURCE_DIR" "$PKGDEB_DIR"

DEBIAN_DIR="$PKGDEB_DIR/DEBIAN";
mkdir -p "$DEBIAN_DIR"

# PREPARE CONTROL FILE
CONTROL_FILE="$DEBIAN_DIR/control";
VERSION="$(git describe --tags || echo "0.SNAPSHOT")";
{
    echo "Package: linux-springboot-packager"
    echo "Version: $VERSION"
    echo "Maintainer: hdsdi3g <admin@hd3g.tv>"
    echo "Architecture: all"
    echo "Section: devel"
    echo "Priority: optional"
    echo "Depends: bash (>=5), coreutils (>=8.3), man-db, pandoc, rpmlint, rpm"
    echo "Recommends: maven"
    echo "Suggests: nodejs, nsis, default-jdk"
    echo "Homepage: https://github.com/hdsdi3g/linux-springboot-packager"
    echo "Description: Create Linux RPM packages and Windows installers"
    echo " for a Spring Boot project."
} > "$CONTROL_FILE"

# PREPARE (FAKE) CHANGELOG
DOC_DIR="$PKGDEB_DIR/usr/share/doc/linux-springboot-packager";
mkdir -p "$DOC_DIR"
{
    echo "linux-springboot-packager ($VERSION) stable; urgency=low"
    echo ""
    echo "  * This package doesn't provide changelog document."
    echo "  Please refer to GitHub project page on"
    echo "  https://github.com/hdsdi3g/linux-springboot-packager"
    echo ""
    echo " -- hdsdi3g <admin@hd3g.tv>  $(LANG="en_US.UTF-8" date '+%a, %d %b %Y %H:%M:%S %z')"
} > "$DOC_DIR/changelog"

# PREPARE MAN
MAN_DIR="$PKGDEB_DIR/usr/share/man/man1";
mkdir -p "$MAN_DIR"
pandoc -s -t man -o "$MAN_DIR/make-springboot-rpm.1" "$ROOT/man-make-springboot-rpm.md"
pandoc -s -t man -o "$MAN_DIR/make-springboot-deb.1" "$ROOT/man-make-springboot-deb.md"
pandoc -s -t man -o "$MAN_DIR/make-springboot-exe.1" "$ROOT/man-make-springboot-exe.md"
pandoc -s -t man -o "$MAN_DIR/search-winsw.bash.1" "$ROOT/search-winsw.bash.md"

# PREPARE COPYRIGHT
{
    echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
    echo "Upstream-Name: Linux Spring Boot Packager"
    echo "Source: https://github.com/hdsdi3g/linux-springboot-packager"
    echo ""
    echo "Files: *"
    echo "Copyright: 2020-$(date '+%Y') hdsdi3g for hd3g.tv"
    echo "License: GPL-3.0"
} > "$DOC_DIR/copyright"

# FIX UNIX RIGHTS FOR NEWER FILES
find "$PKGDEB_DIR/usr/share" -type d -exec chmod 755 {} +
find "$PKGDEB_DIR/usr/share" -type f -not -name copyright -exec gzip -9n {} +
find "$PKGDEB_DIR/usr/share" -type f -exec chmod 644 {} +
find "$PKGDEB_DIR/usr/bin" -type f -exec chmod 755 {} +

chmod 0755 "$PKGDEB_DIR"/usr/lib/linux-springboot-packager/include/*.bash
chmod 0755 "$PKGDEB_DIR"/usr/lib/linux-springboot-packager/templates/*.sh
chmod 0644 "$PKGDEB_DIR"/usr/lib/linux-springboot-packager/templates/*.yml
chmod 0644 "$PKGDEB_DIR"/usr/lib/linux-springboot-packager/templates/debian*
chmod 0644 "$PKGDEB_DIR"/usr/lib/linux-springboot-packager/templates/systemd.service

# CREATE DEB
dpkg-deb --root-owner-group --build pkgdeb
PACKAGE_FILE="linux-springboot-packager-$VERSION.deb";
mv "$(basename "$PKGDEB_DIR").deb" "$PACKAGE_FILE"
lintian --fail-on warning \
    --no-tag-display-limit \
    --suppress-tags debian-changelog-file-missing-or-wrong-name \
    "$PACKAGE_FILE"

echo "";
echo "Now, you can install this app with sudo dpkg -i $PACKAGE_FILE";
