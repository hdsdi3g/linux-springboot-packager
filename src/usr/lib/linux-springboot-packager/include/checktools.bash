#!/bin/bash
#    checktools.bash - check the presence of all mantatory commands to run make-XXX scripts.
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
#    Usage: just source checktools.bash

function check_mktemp() {
    if ! [ -x "$(command -v mktemp)" ]; then
	    echo "Error: mktemp is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_basename() {
    if ! [ -x "$(command -v basename)" ]; then
	    echo "Error: basename is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_realpath() {
    if ! [ -x "$(command -v realpath)" ]; then
	    echo "Error: realpath is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_maven() {
    if ! [ -x "$(command -v "$MVN")" ]; then
        echo "Can't found $MVN!" >&2;
        echo "Please setup maven" >&2;
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
    echo "Use maven ""$(mvn -v | head -1)";
    java -version;
}

function check_rpmbuild() {
    if ! [ -x "$(command -v rpmbuild)" ]; then
    	echo "Error: rpmbuild is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_rpmlint() {
    if ! [ -x "$(command -v rpmlint)" ]; then
    	echo "Error: rpmlint is not installed." >&2
    	exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_pandoc() {
    if ! [ -x "$(command -v pandoc)" ]; then
	    echo "Error: pandoc is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_npm() {
    if ! [ -x "$(command -v "$NPM")" ]; then
        echo "Error: npm is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_xmlstarlet() {
    if ! [ -x "$(command -v xmlstarlet)" ]; then
        echo "Error: xmlstarlet is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_makensis() {
    if ! [ -x "$(command -v makensis)" ]; then
        echo "Error: makensis is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_dpkgdeb() {
    if ! [ -x "$(command -v dpkg-deb)" ]; then
        echo "Error: dpkg-deb is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}

function check_lintian() {
    if ! [ -x "$(command -v lintian)" ]; then
        echo "Error: lintian is not installed." >&2
	    exit "$EXIT_CODE_MISSING_DEPENDENCY_COMMAND";
    fi
}
