#!/bin/bash

function check_basename() {
    if ! [ -x "$(command -v basename)" ]; then
	    echo "Error: basename is not installed." >&2
	    exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
}

function check_realpath() {
    if ! [ -x "$(command -v realpath)" ]; then
	    echo "Error: realpath is not installed." >&2
	    exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
}

function check_maven() {
    if ! [ -x "$(command -v $MVN)" ]; then
        echo "Can't found $MVN!" >&2;
        echo "Please setup maven" >&2;
	    exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
    echo "Use maven "$(mvn -v | head -1);
    java -version;
}

function check_rpmbuild() {
    if ! [ -x "$(command -v rpmbuild)" ]; then
    	echo "Error: rpmbuild is not installed." >&2
	    exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
}

function check_rpmlint() {
    if ! [ -x "$(command -v rpmlint)" ]; then
    	echo "Error: rpmlint is not installed." >&2
    	exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
}

function check_pandoc() {
    if ! [ -x "$(command -v pandoc)" ]; then
	    echo "Error: pandoc is not installed." >&2
	    exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
}

function check_npm() {
    if ! [ -x "$(command -v $NPM)" ]; then
        echo "Error: npm is not installed." >&2
	    exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
}

function check_xmlstarlet() {
    if ! [ -x "$(command -v xmlstarlet)" ]; then
        echo "Error: xmlstarlet is not installed." >&2
	    exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
}

function check_makensis() {
    if ! [ -x "$(command -v makensis)" ]; then
        echo "Error: makensis is not installed." >&2
	    exit $EXIT_CODE_MISSING_DEPENDENCY_COMMAND;
    fi
}
