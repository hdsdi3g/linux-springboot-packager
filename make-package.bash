#!/bin/bash
# shellcheck disable=SC1090
#
# USAGE
# $0 <SpringBoot project path>
# With export SKIP_BUILD=1 for skip maven build if the expected jar exists.
# With export SKIP_NPM=1 for skip npm builds.
# With export SKIP_LINUX=1 for skip Linux builds.

set -eu

MVN="mvn";
MAVEN_OPTS=(--batch-mode -Dorg.slf4j.simpleLogger.defaultLogLevel=WARN -DskipTests -Dgpg.skip=true -Dmaven.javadoc.skip=true -Dmaven.source.skip=true)
NPM="npm";
NPM_OPTS=(install);

#####################
# CHECK TOOL PRESENCE
#####################
if ! [ -x "$(command -v curl)" ]; then
	echo "Error: curl is not installed." >&2
	exit 4
fi
if ! [ -x "$(command -v basename)" ]; then
	echo "Error: basename is not installed." >&2
	exit 4
fi
if ! [ -x "$(command -v realpath)" ]; then
	echo "Error: realpath is not installed." >&2
	exit 4
fi
if ! [ -x "$(command -v java)" ]; then
    echo "Can't found java!" >&2;
    echo "Please setup a valid JDK, version 11+" >&2;
    exit 2;
fi
JAVA=$(which java);

cd "$(dirname "$0")"

####################
# CHECK/GET MAKESELF
####################
MAKESELF="scripts/makeself.sh";
MAKESELF_HEADER="scripts/makeself-header.sh";
if [ ! -f "$MAKESELF" ] ; then
    echo "Can't found Makeself script, download it now"
	curl https://raw.githubusercontent.com/megastep/makeself/master/makeself.sh > $MAKESELF
	curl https://raw.githubusercontent.com/megastep/makeself/master/makeself-header.sh > $MAKESELF_HEADER
fi
chmod +x $MAKESELF

###################
# CHECK FIRST PARAM
###################
if [ "$#" -eq 0 ]; then
    echo "Usage $0 <SpringBoot project path>" >&2;
    echo "The SpringBoot project path must be a Maven project (with pom.xml on root)" >&2;
    exit 1;
fi

########################
# CHECK BASE_DIR PROJECT
########################
BASE_DIR="$1";
if [ ! -d "$BASE_DIR" ]; then
    echo "Directory $BASE_DIR don't exists" >&2;
    exit 2;
fi
BASE_DIR=$(realpath "$1");

########################
# CHECK POM XML PRESENCE
########################
MVN_POM="$BASE_DIR/pom.xml";
if [ ! -f "$MVN_POM" ]; then
    echo "Can't found pom.xml in $BASE_DIR" >&2;
    exit 3;
fi

PACKAGE_DIR="$(pwd)/packages";
mkdir -p "$PACKAGE_DIR";

#########################################
# PREPARE PROJECT DIRECTORY
# COPY ALL TEMPLATES TO PROJECT DIRECTORY
#########################################
PROJECT_DIR="$(pwd)/projects/$(basename "$(realpath "$BASE_DIR")")";
mkdir -p "$PROJECT_DIR";

for TPL_FILE in template/*; do
    TPL_FILE_NAME=$(basename "$TPL_FILE");
    if [ -d "$TPL_FILE" ]; then
        continue;
    fi
    if [ ! -f "$PROJECT_DIR/$TPL_FILE_NAME" ]; then
        cp "$TPL_FILE" "$PROJECT_DIR/$TPL_FILE_NAME";
        echo "Copy $TPL_FILE_NAME to project $PROJECT_DIR, free feel to edit it (you must restart this script after)";
    fi
done

#############################
# CHECK PACKAGE.JSON PRESENCE
# AND BUILD FRONT
#############################
PACKAGE_JSON="$BASE_DIR/package.json";
if [ -f "$PACKAGE_JSON" ] && [ "${SKIP_NPM:-"0"}" = "0" ]; then
    if ! [ -x "$(command -v $NPM)" ]; then
	    echo "Error: npm is not installed." >&2
	    exit 4
    fi
    echo "Build front via \"$NPM ${NPM_OPTS[@]}\"";
    echo "...";
    "$NPM" --prefix "$BASE_DIR" "${NPM_OPTS[@]}" > /dev/null
fi

##########################
# IMPORT POM XML FILE VARS
##########################
MVN_VAR_artifactId="";
MVN_VAR_version="";
MVN_VAR_packaging="";
MVN_VAR_name="";

MVN_VARS="$PROJECT_DIR/mvn-vars.inc.sh";
if [ -f "$MVN_VARS" ]; then
    rm "$MVN_VARS"
fi
scripts/import-mvn-vars "$MVN_POM" "$MVN_VARS"
. "$MVN_VARS"

###############
# MAKE LSM FILE
###############
LSM_FILE="$PROJECT_DIR/meta.lsm";
scripts/make-lsm.bash "$MVN_VARS" "$LSM_FILE"

#####################
# MAKE SPRINGBOOT JAR
#####################
MVN_TARGET="$BASE_DIR/target";
SPRING_EXEC="$MVN_TARGET/$MVN_VAR_artifactId-$MVN_VAR_version.$MVN_VAR_packaging";

if [ -f "$SPRING_EXEC" ] && [ "${SKIP_BUILD:-"0"}" = "1" ]; then
    echo "Skip Maven SpringBoot jar file build";
else
    echo "Start Maven: make SpringBoot jar file..."
    $MVN -f "$MVN_POM" "${MAVEN_OPTS[@]}" clean install
fi

if [ ! -f "$SPRING_EXEC" ] ; then
    echo "Can't find maven compiled file: $SPRING_EXEC" >&2;
    exit 5;
fi

######################################
# COPY SPRINGBOOT JAR FOR THIS PROJECT
######################################
PROJECT_SPRING_EXEC="$PROJECT_DIR/springboot.jar";
if [ -f "$PROJECT_SPRING_EXEC" ] ; then
    rm "$PROJECT_SPRING_EXEC";
fi
cp "$SPRING_EXEC" "$PROJECT_SPRING_EXEC";

######################################################
# MAKE AND IMPORT, IF NEEDED, LIQUIBASE FULL CHANGELOG
######################################################

PROJECT_CHANGELOG="$PROJECT_DIR/database-changelog.xml";
if [ "${SKIP_LINUX:-"0"}" = "0" ]; then
    EXPECTED_CHANGELOG="$BASE_DIR/scripts/db/database-changelog.xml";
    if [ -f "$EXPECTED_CHANGELOG" ] ; then
        EXPECTED_FULL_CHANGELOG="$MVN_TARGET/database-full-archive-changelog.xml";

        if [ -f "$EXPECTED_FULL_CHANGELOG" ] && [ "${SKIP_BUILD:-"0"}" = "1" ] ; then
            echo "Skip Maven remake setupdb archive xml file"
        else
            echo "Start Maven: make setupdb archive xml file..."
            $MVN -f "$MVN_POM" "${MAVEN_OPTS[@]}" setupdb:archive
        fi

        if [ ! -f "$EXPECTED_FULL_CHANGELOG" ] ; then
            echo "Can't found $EXPECTED_FULL_CHANGELOG used by Liquibase and created by tv.hd3g.mvnplugin.setupdb:archive." >&2;
            echo "Only default configuration is allowed here." >&2;
            exit 6;
        fi
        if [ -f "$PROJECT_CHANGELOG" ] ; then
            rm "$PROJECT_CHANGELOG";
        fi
        cp "$EXPECTED_FULL_CHANGELOG" "$PROJECT_CHANGELOG";
    fi
fi

#########################
# MANAGE DEFAULT APP CONF
#########################
PROJECT_APP_CONF="$PROJECT_DIR/application.yml";
if [ ! -f "$PROJECT_APP_CONF" ] ; then
    PROJECT_APP_CONF="$PROJECT_DIR/application.yaml";
    if [ ! -f "$PROJECT_APP_CONF" ] ; then
        PROJECT_APP_CONF="$PROJECT_DIR/application.properties";
        if [ ! -f "$PROJECT_APP_CONF" ] ; then
            PROJECT_APP_CONF="$PROJECT_DIR/application.yml";
            echo "";
            if [ -f "$BASE_DIR/scripts/application-prod.yml" ] ; then
                echo "Can't found default application.yml|yaml|properties in $PROJECT_DIR, copy it from project application-prod.yml...";
                cp "$BASE_DIR/scripts/application-prod.yml" "$PROJECT_APP_CONF"
            elif [ -f "$PROJECT_CHANGELOG" ] ; then
                echo "Can't found default application.yml|yaml|properties in $PROJECT_DIR, copy it from a template (persistence) example...";
                cp "template/examples/application-prod-persistence.yml-example" "$PROJECT_APP_CONF";
            else
                echo "Can't found default application.yml|yaml|properties in $PROJECT_DIR, copy it from a template example...";
                cp "template/examples/application-prod.yml-example" "$PROJECT_APP_CONF";
            fi
            echo "Copied file: $PROJECT_APP_CONF, free feel to edit it (you must restart this script after)";
            echo "This file will be the default configuration file used by setup script.";
        fi
    fi
fi

###############################
# MANAGE DEFAULT LINUX LOG CONF
###############################
if [ "${SKIP_LINUX:-"0"}" = "0" ]; then
    PROJECT_LOG_CONF="$PROJECT_DIR/log4j2.xml";
    if [ ! -f "$PROJECT_LOG_CONF" ] ; then
        echo "";
        if [ -f "$BASE_DIR/scripts/log4j2-prod.xml" ] ; then
            echo "Found default log4j2.xml in $BASE_DIR, copy it from project log4j2-prod.xml...";
            cp "$BASE_DIR/scripts/log4j2-prod.xml" "$PROJECT_LOG_CONF";
        else
            echo "Can't found default log4j2.xml in $PROJECT_DIR, copy it from a template example...";
            cp "template/examples/log4j2-linux-prod.xml-example" "$PROJECT_LOG_CONF";
        fi
        echo "Copied file: $PROJECT_LOG_CONF, free feel to edit it (you must restart this script after)";
        echo "This file will be the default configuration file used by setup script.";
    fi
fi

###################
# COPY SETUP SCRIPT
###################
PROJECT_SETUP="$PROJECT_DIR/setup.sh";
if [ "${SKIP_LINUX:-"0"}" = "0" ]; then
    if [ -f "$PROJECT_SETUP" ] ; then
        rm -f "$PROJECT_SETUP"
    fi
    cp "scripts/setup-linux-prod.sh" "$PROJECT_SETUP";
fi

################################
# MAKE LINUX AUTOEXTRACT PACKAGE
################################
if [ "${SKIP_LINUX:-"0"}" = "0" ]; then
    echo "";
    echo "Assemble autoextract package..."
    LABEL="$MVN_VAR_name version $MVN_VAR_version";
    PACKAGE_FILE="$PACKAGE_DIR/$MVN_VAR_artifactId-$MVN_VAR_version.run.sh";

    if [ -f "$PACKAGE_FILE" ] ; then
        rm -f "$PACKAGE_FILE";
    fi

    scripts/makeself.sh \
        --lsm "$LSM_FILE" \
        --tar-extra "--owner=root --group=root --no-xattrs --no-acls --no-selinux" \
        --nocomp --nooverwrite \
        "$PROJECT_DIR" "$PACKAGE_FILE" "$LABEL" "./setup.sh"
    chmod +x "$PACKAGE_FILE"
fi

########################
# MAKE WINDOWS INSTALLER
########################

if [ -x "$(command -v makensis)" ]; then
    WINDOWS_PATH="$PROJECT_DIR/windows-paths.inc.sh";
    . $WINDOWS_PATH

    echo "Prepare servicewinsw.xml / winsw.xml";
    cp -f "$PROJECT_DIR/servicewinsw.xml" "$PROJECT_DIR/winsw.xml"
    $JAVA \
        -Dreplace.APP_NAME="$MVN_VAR_name" \
        -Dreplace.APP_LONG_NAME="$MVN_VAR_name" \
        -Dreplace.APP_DESCR="$MVN_VAR_description" \
        -Dreplace.WORKING_PATH="$WORKING_PATH\\$MVN_VAR_name" \
        -Dreplace.INSTDIR="$INSTALL_PATH\\$MVN_VAR_name" \
        "$PROJECT_DIR/set-file-vars.java" \
        "$PROJECT_DIR/winsw.xml"
    sed -i $'s/$/\r/' "$PROJECT_DIR/winsw.xml"

    echo "Prepare log4j2.xml for Windows executable"
    cp "template/examples/log4j2-windows-prod.xml-example" "$PROJECT_DIR/log4j2-windows.xml";
    $JAVA \
        -Dreplace.LOG_PATH="$WORKING_PATH\\$MVN_VAR_name" \
        "$PROJECT_DIR/set-file-vars.java" \
        "$PROJECT_DIR/log4j2-windows.xml"
    sed -i $'s/$/\r/' "$PROJECT_DIR/log4j2-windows.xml"

    echo "Build Windows executable...";
    makensis \
        -DWORKING_PATH="$WORKING_PATH\\$MVN_VAR_name" \
        -DINSTALL_PATH="$INSTALL_PATH\\$MVN_VAR_name" \
        -DPROJECT_DIR="$PROJECT_DIR" \
        -DPROJECT_SPRING_EXEC="$PROJECT_SPRING_EXEC" \
        -DWINSW_EXEC_PATH="$(scripts/search-winsw)" \
        -DVERSION="$MVN_VAR_version" \
        -DAPP_NAME="$MVN_VAR_name" \
        -DAPP_LONG_NAME="$MVN_VAR_name" \
        -DAPP_DESCR="$MVN_VAR_description" \
        -DAPP_URL="$MVN_VAR_organization_url" \
        -DAPP_VENDOR="$MVN_VAR_organization_name $MVN_VAR_organization_url" \
        -INPUTCHARSET UTF8 -WX \
        scripts/builder.nsi
    
    echo "Clean temp files for Windows executable"
    rm -f "$PROJECT_DIR/winsw.xml";
    rm -f "$PROJECT_DIR/log4j2-windows.xml";

    echo "";
    echo "$MVN_VAR_name $MVN_VAR_version Windows installer executable is now ready on packages directory.";
else
    echo "makensis not found, skip Windows executable build";
fi

##################
# CLEAN TEMP FILES
##################

rm "$MVN_VARS"
rm "$LSM_FILE"
rm "$PROJECT_SPRING_EXEC"
if [ -f "$PROJECT_SETUP" ] ; then
    rm "$PROJECT_SETUP";
fi
if [ -f "$PROJECT_CHANGELOG" ] ; then
    rm "$PROJECT_CHANGELOG";
fi

if [ "${SKIP_LINUX:-"0"}" = "0" ]; then
    echo "";
    echo "$MVN_VAR_name $MVN_VAR_version package is now ready to be deployed on Linux/WSL host";
    echo "";
    echo "Usage for a simple autoextract test/check: ./$(basename "$PACKAGE_FILE") --keep --target \"extracted\" [-- -norun]";
    echo "Usage for deploy to another root directory: ./$(basename "$PACKAGE_FILE") [-- -chroot \"/opt\"]";
fi
