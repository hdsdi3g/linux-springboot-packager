#!/bin/bash
# shellcheck disable=SC1090
#
# USAGE
# $0 <SpringBoot project path>
# With export SKIP_BUILD=1 for skip maven build if the expected jar exists.

set -eu

MVN="mvn";
MAVEN_OPTS=(--batch-mode -Dorg.slf4j.simpleLogger.defaultLogLevel=WARN -DskipTests -Dgpg.skip=true -Dmaven.javadoc.skip=true -Dmaven.source.skip=true)

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
EXPECTED_CHANGELOG="$BASE_DIR/scripts/db/database-changelog.xml";
PROJECT_CHANGELOG="$PROJECT_DIR/database-changelog.xml";
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
            echo "Can't found default application.yml|yaml|properties in $PROJECT_DIR, copy it from a template example...";

            if [ -f "$PROJECT_CHANGELOG" ] ; then
                cp "template/examples/application-prod-persistence.yml-example" "$PROJECT_APP_CONF";
            else
                cp "template/examples/application-prod.yml-example" "$PROJECT_APP_CONF";
            fi

            echo "Copied file: $PROJECT_APP_CONF, free feel to edit it (you must restart this script after)";
            echo "This file will be the default configuration file used by setup script.";
        fi
    fi
fi

#########################
# MANAGE DEFAULT LOG CONF
#########################
PROJECT_LOG_CONF="$PROJECT_DIR/log4j2.xml";
if [ ! -f "$PROJECT_LOG_CONF" ] ; then
    echo "";
    echo "Can't found default log4j2.xml in $PROJECT_DIR, copy it from a template example...";
    cp "template/examples/log4j2-linux-prod.xml-example" "$PROJECT_LOG_CONF";
    echo "Copied file: $PROJECT_LOG_CONF, free feel to edit it (you must restart this script after)";
    echo "This file will be the default configuration file used by setup script.";
fi

###################
# COPY SETUP SCRIPT
###################
PROJECT_SETUP="$PROJECT_DIR/setup.sh";
if [ -f "$PROJECT_SETUP" ] ; then
    rm -f "$PROJECT_SETUP"
fi
cp "scripts/setup-linux-prod.sh" "$PROJECT_SETUP";

##########################
# MAKE AUTOEXTRACT PACKAGE
##########################
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
    --nocomp \
    "$PROJECT_DIR" "$PACKAGE_FILE" "$LABEL" "./setup.sh"
chmod +x "$PACKAGE_FILE"

##################
# CLEAN TEMP FILES
##################

rm "$MVN_VARS"
rm "$LSM_FILE"
rm "$PROJECT_SPRING_EXEC"
rm "$PROJECT_SETUP"
if [ -f "$PROJECT_CHANGELOG" ] ; then
    rm "$PROJECT_CHANGELOG";
fi

echo "";
echo "$MVN_VAR_name $MVN_VAR_version package is now ready to be deployed on Linux/WSL host";
echo "";
echo "Usage for a simple autoextract test/check: ./$(basename "$PACKAGE_FILE") --keep --target \"extracted\" [-- -norun]";
echo "Usage for deploy to another root directory: ./$(basename "$PACKAGE_FILE") [-- -chroot \"/opt\"]";
