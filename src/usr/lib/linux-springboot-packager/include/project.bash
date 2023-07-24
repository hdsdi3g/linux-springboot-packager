#!/bin/bash
#    project.bash - load all setups and builds functions used by make-XXX scripts
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
#    Usage: just source project.bash
#
#    shellcheck disable=SC2124

function project_load_base_dir() {
    BASE_DIR="$1";
    if [ ! -d "$BASE_DIR" ]; then
        echo "Directory $BASE_DIR don't exists" >&2;
        exit "$EXIT_CODE_MISSING_PROJECT_DIR";
    fi
    BASE_DIR=$(realpath "$1");

    MVN_POM="$BASE_DIR/pom.xml";
    if [ ! -f "$MVN_POM" ]; then
        echo "Can't found pom.xml in $BASE_DIR" >&2;
        exit "$EXIT_CODE_MISSING_POM";
    fi
}

function make_front() {
    PACKAGE_JSON="$BASE_DIR/package.json";
    if [ -f "$PACKAGE_JSON" ] && [ "${SKIP_NPM:-"0"}" = "0" ]; then
        check_npm;
        echo "Build front via \"$NPM" "${NPM_OPTS[@]}" "\"";
        echo "...";
        "$NPM" --prefix "$BASE_DIR" "${NPM_OPTS[@]}" > /dev/null
    fi
}

function extract_var_from_pom() {
    XPATH="$1";
    FILENAME="$2";
    DEFAULT_VALUE="$3";
    RESULT=$(xmlstarlet sel -N x="http://maven.apache.org/POM/4.0.0" -t -m "$XPATH" -v . "$FILENAME" || echo "$DEFAULT_VALUE");
    if [ "$RESULT" = "" ]; then
        echo "Missing pom entry: $XPATH" | sed -e "s~x:~~g;s~//~/~g;" >&2
        exit "$EXIT_CODE_MISSING_POM_ENTRY";
    fi
    echo "$RESULT";
}

function load_mvn_vars() {
    set -eu
    local TEMP_FULL_POM
    if [ "${SKIP_IMPORT_POM:-"0"}" = "0" ]; then
        TEMP_FULL_POM=$(mktemp -u)"-effective-pom.xml";
    else
        mkdir -p "$BASE_DIR/target";
        TEMP_FULL_POM="$BASE_DIR/target/$(basename "$(dirname "$MVN_POM")")-effective-pom.xml";
    fi

    if [ ! -f "$TEMP_FULL_POM" ]; then
        echo "Load effective pom XML to $TEMP_FULL_POM";
        $MVN -f "$MVN_POM" "${MAVEN_OPTS[@]}" help:effective-pom -Doutput="$TEMP_FULL_POM"
    fi

    VERSION=$(extract_var_from_pom //x:project/x:version "$TEMP_FULL_POM" "");
    ARTIFACTID=$(extract_var_from_pom //x:project/x:artifactId "$TEMP_FULL_POM" "");
    PACKAGING=$(extract_var_from_pom //x:project/x:packaging "$TEMP_FULL_POM" "jar");
    NAME=$(extract_var_from_pom //x:project/x:name "$TEMP_FULL_POM" "");
    SHORT_DESCRIPTION=$(extract_var_from_pom //x:project/x:description "$TEMP_FULL_POM" "");
    ORG_NAME=$(extract_var_from_pom //x:project/x:organization/x:name "$TEMP_FULL_POM" "");
    ORG_URL=$(extract_var_from_pom //x:project/x:organization/x:url "$TEMP_FULL_POM" "");
    URL=$(extract_var_from_pom //x:project/x:url "$TEMP_FULL_POM" "$ORG_URL");
    LICENCE=$(extract_var_from_pom //x:project/x:licenses/x:license/x:name "$TEMP_FULL_POM" "");
    AUTHOR_NAME=$(extract_var_from_pom //x:project/x:developers/x:developer[1]/x:name "$TEMP_FULL_POM" "");
    AUTHOR_EMAIL=$(extract_var_from_pom //x:project/x:developers/x:developer[1]/x:email "$TEMP_FULL_POM" "");
    JAVA_VERSION=$(extract_var_from_pom //x:project/x:properties/x:java.version "$TEMP_FULL_POM" "8");
    ISSUE_MANAGEMENT_NAME=$(extract_var_from_pom //x:project/x:issueManagement/x:system "$TEMP_FULL_POM" "");
    ISSUE_MANAGEMENT_URL=$(extract_var_from_pom //x:project/x:issueManagement/x:url "$TEMP_FULL_POM" "");
    LOGBACK_VERSION=$(extract_var_from_pom "//x:project/x:dependencies/x:dependency[x:scope='compile' and x:groupId='ch.qos.logback' and x:artifactId='logback-classic']/x:version" "$TEMP_FULL_POM" "$NOT_FOUND");
    LOG4J2_VERSION=$(extract_var_from_pom "//x:project/x:dependencies/x:dependency[x:scope='compile' and x:groupId='org.apache.logging.log4j' and x:artifactId='log4j-api']/x:version" "$TEMP_FULL_POM" "$NOT_FOUND");

    if [ "${SKIP_IMPORT_POM:-"0"}" = "0" ]; then
        rm -f "$TEMP_FULL_POM";
    else
        echo "Keep actual extracted full pom file.";
    fi
}

function def_linux_base_dir_vars() {
    OUTPUT_DIR_CONF="/etc/$ARTIFACTID";
    OUTPUT_DIR_DEFAUT="/etc/default";
    OUTPUT_DIR_SYSTEMD="/etc/systemd/system";
    OUTPUT_DIR_MAN="/usr/local/share/man/man8";
    OUTPUT_DIR_APP="/usr/lib/$ARTIFACTID";
    OUTPUT_DIR_LOG="/var/log/$ARTIFACTID";
    OUTPUT_DIR_USER="/var/lib/$ARTIFACTID";
}

function def_linux_deb_base_dir_vars() {
    OUTPUT_DIR_MAN="/usr/share/man/man8";
    OUTPUT_DIR_APP="/usr/share/$ARTIFACTID";
    OUTPUT_DIR_DOC="/usr/share/doc/$ARTIFACTID";
}

function def_windows_base_dir_vars() {
    OUTPUT_DIR_CONF="C:\\ProgramData\\$ARTIFACTID";
    OUTPUT_DIR_DEFAUT="";
    OUTPUT_DIR_SYSTEMD="";
    OUTPUT_DIR_MAN="C:\\Program Files\\$ARTIFACTID";
    OUTPUT_DIR_APP="C:\\Program Files\\$ARTIFACTID";
    OUTPUT_DIR_LOG="C:\\ProgramData\\$ARTIFACTID";
    OUTPUT_DIR_USER="C:\\ProgramData\\$ARTIFACTID";
}

function def_files_dir_vars() {
    OUTPUT_JAR_NAME="$ARTIFACTID-bin.jar";
    OUTPUT_JAR_FILE="$OUTPUT_DIR_APP/$OUTPUT_JAR_NAME";

    OUTPUT_APPCONF_NAME="application.yml";
    OUTPUT_APPCONF_FILE="$OUTPUT_DIR_CONF/$OUTPUT_APPCONF_NAME";

    if [ "$LOGBACK_VERSION" != "$NOT_FOUND" ]; then
        OUTPUT_LOGCONF_NAME="logback.xml";
    elif [ "$LOG4J2_VERSION" != "$NOT_FOUND" ]; then
        OUTPUT_LOGCONF_NAME="log4j2.xml";
    else
        echo "Can't found the application logger (log4j or logback)" >&2
        exit "$EXIT_CODE_CANT_FOUND_APP_LOGGER";
    fi
    OUTPUT_LOGCONF_FILE="$OUTPUT_DIR_CONF/$OUTPUT_LOGCONF_NAME";

    OUTPUT_MAN_NAME="$ARTIFACTID.8";
    OUTPUT_MAN_FILE="$OUTPUT_DIR_MAN/$OUTPUT_MAN_NAME";
    
    OUTPUT_SERVICE_NAME="$ARTIFACTID.service";
    OUTPUT_SERVICE_FILE="$OUTPUT_DIR_SYSTEMD/$OUTPUT_SERVICE_NAME";
    OUTPUT_SERVICE_LINK="$OUTPUT_DIR_APP/$OUTPUT_SERVICE_NAME";

    OUTPUT_ENV_NAME="$ARTIFACTID";
    OUTPUT_ENV_FILE="$OUTPUT_DIR_DEFAUT/$OUTPUT_ENV_NAME";

    OUTPUT_LICENCE_NAME="LICENCE.txt";
    OUTPUT_LICENCE_FILE="$OUTPUT_DIR_APP/$OUTPUT_LICENCE_NAME";
    OUTPUT_THIRDPARTY_NAME="THIRD-PARTY.txt";
    OUTPUT_THIRDPARTY_FILE="$OUTPUT_DIR_APP/$OUTPUT_THIRDPARTY_NAME";
}

function make_replace_list_vars() {
    local REPLACE_LIST=(
        "s~@NAME@~$NAME~g;"
        "s~@SHORT_DESCRIPTION@~$SHORT_DESCRIPTION~g;"
        "s~@APP_NAME@~$ARTIFACTID~g;"
        "s~@VERSION@~$VERSION~g;"
        "s~@DEB_RELEASE@~$DEB_RELEASE~g;"
        "s~@JAVA@~$JAVA~g;"
        "s~@SERVICE_NAME@~$ARTIFACTID~g;"
        "s~@SERVICE_USER_NAME@~$ARTIFACTID~g;"
        "s~@SERVICE_FILE@~/etc/systemd/system/$ARTIFACTID.service~g;"
        "s~@USER_HOME_DIR@~$OUTPUT_DIR_USER~g;"
        "s~@ISSUE_MANAGEMENT_NAME@~$ISSUE_MANAGEMENT_NAME~g;"
        "s~@ISSUE_MANAGEMENT_URL@~$ISSUE_MANAGEMENT_URL~g;"
        "s~@NOW@~$NOW~g;"
        "s~@YEAR@~$YEAR~g;"
        "s~@SHORT_DATE@~$SHORT_DATE~g;"
        "s~@DEB_CHANGELOG_DATE@~$DEB_CHANGELOG_DATE~g;"
        "s~@ORG_NAME@~$ORG_NAME~g;"
        "s~@ORG_URL@~$ORG_URL~g;"
        "s~@URL@~$URL~g;"
        "s~@LICENCE@~$LICENCE~g;"
        "s~@AUTHOR_NAME@~$AUTHOR_NAME~g;"
        "s~@AUTHOR_EMAIL@~$AUTHOR_EMAIL~g;"
        "s~@JAVA_VERSION@~$JAVA_VERSION~g;"
        "s~@OUTPUT_DIR_CONF@~$OUTPUT_DIR_CONF~g;"
        "s~@OUTPUT_DIR_DEFAUT@~$OUTPUT_DIR_DEFAUT~g;"
        "s~@OUTPUT_DIR_SYSTEMD@~$OUTPUT_DIR_SYSTEMD~g;"
        "s~@OUTPUT_DIR_MAN@~$OUTPUT_DIR_MAN~g;"
        "s~@OUTPUT_DIR_APP@~$OUTPUT_DIR_APP~g;"
        "s~@OUTPUT_DIR_LOG@~$OUTPUT_DIR_LOG~g;"
        "s~@OUTPUT_DIR_USER@~$OUTPUT_DIR_USER~g;"
        "s~@OUTPUT_JAR_NAME@~$OUTPUT_JAR_NAME~g;"
        "s~@OUTPUT_JAR_FILE@~$OUTPUT_JAR_FILE~g;"
        "s~@OUTPUT_APPCONF_NAME@~$OUTPUT_APPCONF_NAME~g;"
        "s~@OUTPUT_APPCONF_FILE@~$OUTPUT_APPCONF_FILE~g;"
        "s~@OUTPUT_LOGCONF_NAME@~$OUTPUT_LOGCONF_NAME~g;"
        "s~@OUTPUT_LOGCONF_FILE@~$OUTPUT_LOGCONF_FILE~g;"
        "s~@OUTPUT_MAN_NAME@~$OUTPUT_MAN_NAME~g;"
        "s~@OUTPUT_MAN_FILE@~$OUTPUT_MAN_FILE~g;"
        "s~@OUTPUT_SERVICE_NAME@~$OUTPUT_SERVICE_NAME~g;"
        "s~@OUTPUT_SERVICE_FILE@~$OUTPUT_SERVICE_FILE~g;"
        "s~@OUTPUT_SERVICE_LINK@~$OUTPUT_SERVICE_LINK~g;"
        "s~@OUTPUT_ENV_NAME@~$OUTPUT_ENV_NAME~g;"
        "s~@OUTPUT_ENV_FILE@~$OUTPUT_ENV_FILE~g;"
        "s~@OUTPUT_LICENCE_NAME@~$OUTPUT_LICENCE_NAME~g;"
        "s~@OUTPUT_LICENCE_FILE@~$OUTPUT_LICENCE_FILE~g;"
        "s~@OUTPUT_THIRDPARTY_NAME@~$OUTPUT_THIRDPARTY_NAME~g;"
        "s~@OUTPUT_THIRDPARTY_FILE@~$OUTPUT_THIRDPARTY_FILE~g;"
    );

    REPLACE="${REPLACE_LIST[@]}";
}

function prepare_rpm_build_dir() {
    RPM_WORKING_DIR=$(mktemp -u -d -t "lsbp_RPM_""$ARTIFACTID""_XXXXXX");
    echo "Working dir: $RPM_WORKING_DIR";
    mkdir -p "$RPM_WORKING_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    BUILD_DIR="$RPM_WORKING_DIR/BUILD";

    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_CONF";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_DEFAUT";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_SYSTEMD";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_MAN";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_APP";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_LOG";
}

function prepare_deb_build_dir() {
    DEB_WORKING_DIR=$(mktemp -u -d -t "lsbp_DEB_""$ARTIFACTID""_XXXXXX");
    echo "Working dir: $DEB_WORKING_DIR";
    DEBIAN_DIR="$DEB_WORKING_DIR/DEBIAN";
    mkdir -p "$DEBIAN_DIR"
    BUILD_DIR="$DEB_WORKING_DIR";
    
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_CONF";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_DEFAUT";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_SYSTEMD";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_MAN";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_APP";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_LOG";
    mkdir -p "$BUILD_DIR/$OUTPUT_DIR_DOC";
}

function prepare_exe_build_dir() {
    EXE_WORKING_DIR=$(mktemp -u -d -t "lsbp__EXE_""$ARTIFACTID""_XXXXXX");
    echo "Working dir: $EXE_WORKING_DIR";
    mkdir -p "$EXE_WORKING_DIR"
    BUILD_DIR="$EXE_WORKING_DIR";

    OUTPUT_JAR_FILE="$OUTPUT_JAR_NAME";
    OUTPUT_APPCONF_FILE="$OUTPUT_APPCONF_NAME";
    OUTPUT_LOGCONF_FILE="$OUTPUT_LOGCONF_NAME";
    OUTPUT_MAN_FILE="$OUTPUT_MAN_NAME";
    OUTPUT_LICENCE_FILE="$OUTPUT_LICENCE_NAME";
    OUTPUT_THIRDPARTY_FILE="$OUTPUT_THIRDPARTY_NAME";
}

function make_jar() {
    local MVN_TARGET="$BASE_DIR/target";
    SPRING_EXEC="$MVN_TARGET/$ARTIFACTID-$VERSION.$PACKAGING";

    if [ -f "$SPRING_EXEC" ] && [ "${SKIP_BUILD:-"0"}" = "1" ]; then
        echo "Skip Maven SpringBoot jar file build";
    else
        echo "Start Maven: make SpringBoot jar file..."
        $MVN -f "$MVN_POM" "${MAVEN_OPTS[@]}" clean install
    fi

    if [ ! -f "$SPRING_EXEC" ] ; then
        echo "Can't find maven compiled file: $SPRING_EXEC" >&2;
        exit "$EXIT_CODE_CANT_FOUND_JAR_FILE_OUTPUT";
    fi
    cp "$SPRING_EXEC" "$BUILD_DIR/$OUTPUT_JAR_FILE";
}

function extract_default_app_conf() {
    DEFAULT_CONF=$(find "$BASE_DIR" -not -path '*/.*' -not -path '*/node_modules/*' -not -path '*/target/*' -name "application.yml.example" | head -1);
    if [ -f "$DEFAULT_CONF" ] ; then
        echo "Use $DEFAULT_CONF as default configuration file, provided by project";
    else
        local SEARCH_EXTS=(yml yaml properties);
        for EXT in "${SEARCH_EXTS[@]}"; do
            DEFAULT_CONF="$BASE_DIR/scripts/application-prod.$EXT";
            if [ -f "$DEFAULT_CONF" ] ; then
                echo "Use $DEFAULT_CONF as default configuration file, provided for production, by project";
                exit 0;    
            fi
        done
        echo "Can't found a default application.yml|yaml|properties provided by the project, use a template example.";
        DEFAULT_CONF="$TEMPLATES_DIR/application-prod.yml";
    fi
    if [ ! -f "$DEFAULT_CONF" ] ; then
        echo "Can't found example configuration: $DEFAULT_CONF" >&2;
        exit "$EXIT_CODE_CANT_FOUND_DEFAULT_CONF";
    fi

    if [[ "$DEFAULT_CONF" == *"properties"* ]]; then
        OUTPUT_APPCONF_NAME="application.properties";
        OUTPUT_APPCONF_FILE="$OUTPUT_DIR_CONF/$OUTPUT_APPCONF_NAME";
    fi

    cp "$DEFAULT_CONF" "$BUILD_DIR/$OUTPUT_APPCONF_FILE";
}

function extract_default_linux_log_conf() {
    if [ "$LOGBACK_VERSION" != "$NOT_FOUND" ]; then
        echo "Detect logback version $LOGBACK_VERSION on dependencies"
        DEFAULT_LOG_CONF="$TEMPLATES_DIR/logback-linux-prod.xml";
    elif [ "$LOG4J2_VERSION" != "$NOT_FOUND" ]; then
        echo "Detect log4j version $LOG4J2_VERSION on dependencies"
        DEFAULT_LOG_CONF="$TEMPLATES_DIR/log4j2-linux-prod.xml";
    fi

    if [ ! -f "$DEFAULT_LOG_CONF" ] ; then
        echo "Can't found example log configuration: $DEFAULT_LOG_CONF";
        exit "$EXIT_CODE_CANT_FOUND_LOG_CONF";
    fi
    sed -e "$REPLACE" < "$DEFAULT_LOG_CONF" > "$BUILD_DIR/$OUTPUT_LOGCONF_FILE"
}

function extract_default_windows_log_conf() {
    if [ -f "$BASE_DIR/scripts/log4j2-windows-prod.xml" ] ; then
        echo "Found a default log4j2.xml provided by project";
        DEFAULT_LOG_CONF="$BASE_DIR/scripts/log4j2-windows-prod.xml";
    else
        DEFAULT_LOG_CONF="$TEMPLATES_DIR/log4j2-windows-prod.xml";
    fi
    if [ ! -f "$DEFAULT_LOG_CONF" ] ; then
        echo "Can't found example log configuration: $DEFAULT_LOG_CONF";
        exit "$EXIT_CODE_CANT_FOUND_LOG_CONF";
    fi
    sed -e "$REPLACE" < "$DEFAULT_LOG_CONF" > "$BUILD_DIR/$OUTPUT_LOGCONF_FILE"
    sed -i $'s/$/\r/' "$BUILD_DIR/$OUTPUT_LOGCONF_FILE";
}

function make_man_page() {
    sed -e "$REPLACE" < "$TEMPLATES_DIR/template-man.md" | pandoc -s -t man -o "$BUILD_DIR/$OUTPUT_MAN_FILE"
}

function make_html_doc_page() {
    OUTPUT_MAN_FILE="$ARTIFACTID.html";
    sed -e "$REPLACE" < "$TEMPLATES_DIR/template-man.md" | pandoc -s -t html -o "$BUILD_DIR/$OUTPUT_MAN_FILE"
}

function make_service_conf() {
    sed -e "$REPLACE" < "$TEMPLATES_DIR/systemd.service" > "$BUILD_DIR/$OUTPUT_SERVICE_FILE"
    echo "#ENV CONF FOR $NAME" > "$BUILD_DIR/$OUTPUT_ENV_FILE";
}

function make_winsw_conf() {
    OUTPUT_SERVICE_FILE="winsw.xml";
    sed -e "$REPLACE" < "$TEMPLATES_DIR/servicewinsw.xml" > "$BUILD_DIR/$OUTPUT_SERVICE_FILE";
    sed -i $'s/$/\r/' "$BUILD_DIR/$OUTPUT_SERVICE_FILE";
}

function make_nsi_conf() {
    WINSW_EXEC_PATH="$1";
    OUTPUT_NSI_FILE="builder.nsi";
    sed -e "$REPLACE" < "$TEMPLATES_DIR/builder.nsi" > "$BUILD_DIR/$OUTPUT_NSI_FILE";
    sed -i "s~@WINSW_EXEC_PATH@~$WINSW_EXEC_PATH~g;" "$BUILD_DIR/$OUTPUT_NSI_FILE";
    sed -i "s~@BUILD_DIR@~$(realpath "$BUILD_DIR")~g;" "$BUILD_DIR/$OUTPUT_NSI_FILE";
}

function extract_information_files() {
    if [ -f "$BASE_DIR/LICENCE" ]; then
        cp "$BASE_DIR/LICENCE" "$BUILD_DIR/$OUTPUT_LICENCE_FILE";
    elif [ -f "$BASE_DIR/LICENCE.TXT" ]; then
        cp "$BASE_DIR/LICENCE.TXT" "$BUILD_DIR/$OUTPUT_LICENCE_FILE";
    elif [ -f "$BASE_DIR/LICENCE.txt" ]; then
        cp "$BASE_DIR/LICENCE.txt" "$BUILD_DIR/$OUTPUT_LICENCE_FILE";
    fi
    if [ -f "$BASE_DIR/THIRD-PARTY.txt" ]; then
        cp "$BASE_DIR/THIRD-PARTY.txt" "$BUILD_DIR/$OUTPUT_THIRDPARTY_FILE";
    fi
}

function sed_usr_lib() {
    sed -e "s~/usr/lib~%{_libdir}~g;" < /dev/stdin;
}

function clean_after_build() {
    set -eu
    if [ "${SKIP_CLEAN:-"0"}" = "0" ]; then
        local TEMP_DIR="$1";
        if [ -d "$TEMP_DIR" ]; then
            echo "Delete temp (working dir): $TEMP_DIR";
            rm -rf "$TEMP_DIR"
        fi
    fi
}

function check_destination_dir() {
    BUILD_DESTINATION_DIR="${2:-"."}";
    BUILD_DESTINATION_DIR=$(realpath "$BUILD_DESTINATION_DIR");
    if [ ! -d "$BUILD_DESTINATION_DIR" ]; then
        echo "Can't found destination directory: $BUILD_DESTINATION_DIR" >&2;
        exit "$EXIT_CODE_CANT_FOUND_DEST_DIR";
    fi
}
