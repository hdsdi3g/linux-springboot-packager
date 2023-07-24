#!/bin/bash
#    run-tests - run implemented self end-to-end tests
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
#    Usage: ./run-tests

set -eu

cd "$(dirname "$0")"

###################
# SETUP TESTS ZONE
###################

PREFIX="src";
export PREFIX="$PREFIX";
TESTROOT="test";

TEST_TEMP_DIR="$TESTROOT/temp";
if [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR";
fi
mkdir -p "$TEST_TEMP_DIR";

################
# DEB TEST ZONE
################
"$PREFIX/usr/bin/make-springboot-deb" "$TESTROOT/demospringboot" "$TEST_TEMP_DIR"

EXPECTED_TEST_PACKAGE="$TEST_TEMP_DIR/demospringboot-0.0.1-SNAPSHOT.deb";
if [ ! -f "$EXPECTED_TEST_PACKAGE" ]; then
    echo "Error: can't found builded package: $EXPECTED_TEST_PACKAGE" >&2;
    exit 1;
fi

################
# RPM TEST ZONE
################

"$PREFIX/usr/bin/make-springboot-rpm" "$TESTROOT/demospringboot" "$TEST_TEMP_DIR"

EXPECTED_TEST_PACKAGE="$TEST_TEMP_DIR/demospringboot-0.0.1-SNAPSHOT.rpm";
if [ ! -f "$EXPECTED_TEST_PACKAGE" ]; then
    echo "Error: can't found builded package: $EXPECTED_TEST_PACKAGE" >&2;
    exit 1;
fi

RMP_QI="$TEST_TEMP_DIR/rpm-qi.txt";
rpm -qi "$EXPECTED_TEST_PACKAGE" > $RMP_QI;

function assert_equals() {
    local ATTR;
    ATTR=$(grep "$1" $RMP_QI | head -1 | cut -d ":" -f 2 | xargs);
    if [ "$ATTR" != "$2" ]; then
        echo "Error: invalid package information [$1], expected $2, but was $ATTR" >&2;
        exit 1;
    fi
}

assert_equals Name demospringboot;
assert_equals Version 0.0.1.SNAPSHOT;
assert_equals Architecture noarch;
assert_equals Group "System Environment/Daemons";
assert_equals License "GNU General Public License, Version 3";
assert_equals Signature "(none)"
assert_equals Vendor "hd3g.tv"

RMP_QLP="$TEST_TEMP_DIR/rpm-qlp.txt";
rpm -qlp "$EXPECTED_TEST_PACKAGE" > "$RMP_QLP"

function assert_contain() {
    if ! grep -q "$1" "$RMP_QLP"; then
        echo "Error: can't found file $1, in builded package" >&2;
        exit 1;
    fi
}

assert_contain "/etc/default/demospringboot";
assert_contain "/etc/demospringboot";
assert_contain "/etc/demospringboot/application.yml";
assert_contain "/etc/demospringboot/logback.xml";
assert_contain "/usr/lib/demospringboot";
assert_contain "/usr/lib/demospringboot/THIRD-PARTY.txt";
assert_contain "/usr/lib/demospringboot/LICENCE.txt";
assert_contain "/usr/lib/demospringboot/demospringboot-bin.jar";
assert_contain "/etc/systemd/system/demospringboot.service";
assert_contain "/usr/local/share/man/man8/demospringboot.8";
assert_contain "/var/log/demospringboot";

################
# EXE TEST ZONE
################

if  [ -x "$(command -v makensis)" ]; then
    echo "Empty" > "$PREFIX/usr/lib/linux-springboot-packager/templates/WinSW-x64.exe"
    "$PREFIX/usr/bin/make-springboot-exe" "$TESTROOT/demospringboot" "$TEST_TEMP_DIR"
fi

################
# CLEAN ZONE
################

if [ -d "$PREFIX/tmp" ]; then
    rm -rf "$PREFIX/tmp";
fi

echo "Tests are ok";
