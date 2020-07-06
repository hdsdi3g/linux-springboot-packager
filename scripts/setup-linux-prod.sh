#!/bin/bash
# shellcheck disable=SC1090
#
# USAGE
# Inside an extracted package created with make-package.bash and makeself
# package.run.sh -- -norun
#                               Don't run this script, only test makeself extraction
# package.run.sh -- -chroot /dir
#                               All destinations paths will be started with "/dir".
#                               Usefull for test this script without touch sensible directories.
# With export SKIP_LIQUIBASE=1 for skip Liquibase operations

set -eu
umask 022

############
# PRE-CHECKS
############
if [ "$(uname)" != "Linux" ]; then
    echo "This setup script is intended for a Linux host"
    echo "No setup will be done here"
    exit 0;
fi

ROOT="";
if [ $# -gt 0 ]; then
    if [ "$1" == "-norun" ]; then
        echo "This setup script is disabled (norun mode)" >&2;
        echo "No setup will be done here" >&2;
        exit 0;
    elif [ "$1" == "-chroot" ]; then
        ROOT="$2";
        echo "Change root to $ROOT";
        if ! [ "$EUID" -ne 0 ]; then
            echo "This script don't run as root: skip user creation and service register";
        fi
	elif [ "$EUID" -ne 0 ]; then
    	echo "Please run this script as root" >&2;
    	exit 1;
    fi
fi

if ! [ -x "$(command -v java)" ]; then
    echo "Can't found java!" >&2;
    echo "Please setup a valid JDK, version 11+" >&2;
    exit 2;
fi
JAVA=$(which java);

################
# LOAD BASE VARS
################
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd "$BASE_DIR";

MVN_VAR_description="";
MVN_VAR_version="";
MVN_VAR_artifactId="";
MVN_VAR_version="";
MVN_VAR_name="";
MVN_VAR_description="";
MVN_VAR_organization_url="";

. "$BASE_DIR/mvn-vars.inc.sh"
BIN_DIR="$ROOT/usr/bin";

if [ ! -d "$BIN_DIR" ] ; then
	mkdir -p "$BIN_DIR";
fi

APP_NAME="$MVN_VAR_artifactId";
CONF_DIR="$ROOT/etc/$APP_NAME";
DEFAULT_FILE="$ROOT/etc/default/$APP_NAME";
LIB_DIR="$ROOT/usr/lib/$APP_NAME";
SYSTEMD_DIR="$ROOT/etc/systemd/system";
SERVICE_NAME="$APP_NAME";
CURRENT_APP_VERSION_FILE="$CONF_DIR/version";
CURRENT_APP_RUNAS_FILE="$CONF_DIR/deploy-run-as";
DATABASE_CHANGELOG="$BASE_DIR/database-changelog.xml";

################
# WELCOME ABOARD
################
echo "This setup script is intended for deploy $MVN_VAR_description"
if [ -f "$CURRENT_APP_VERSION_FILE" ]; then
    echo -n "Current installed version: $(cat "$CURRENT_APP_VERSION_FILE"), "
    stat -c %y "$CURRENT_APP_VERSION_FILE" | cut -d . -f 1
fi
echo -n "Packaged version:          $MVN_VAR_version, "
stat -c %y "$BASE_DIR/mvn-vars.inc.sh" | cut -d . -f 1 

if [ -f "$CURRENT_APP_VERSION_FILE" ]; then
    echo "";
    echo "This script will extract the application and overwrite all the actual dependencies.";
    if [ "$EUID" -eq 0 ]; then
        echo "It will stop and disable the service before the extraction: you will must enable and start it manually after.";
    else
        echo "You'll must restart and disable and enable the service it manually after, as root.";
    fi
    if [ -f "$DATABASE_CHANGELOG" ]; then
        echo "It will not touch to the database configuration, but it will upgrade the database if needed.";
    fi
    read -n 1 -r -p "Press any key to continue"
else
    echo "";
    echo "This script will extract the application and the dependencies.";
    if [ -f "$DATABASE_CHANGELOG" ]; then
        echo "It will ask you database credentials, and setup it.";
    fi
    echo "After the setup, you will need to activate and start the service manually.";
    read -n 1 -r -p "Press any key to continue"
fi

##################
# PREPARE BASE DIR
##################

mkdir -p "$ROOT/etc/default";
mkdir -p "$CONF_DIR";
mkdir -p "$SYSTEMD_DIR";
mkdir -p "$ROOT/var/lib";
mkdir -p "$BIN_DIR";
mkdir -p "$LIB_DIR";

########################
# STOP & DISABLE SERVICE
########################
if [ "$EUID" -eq 0 ]; then
    COUNT_SERVICE_ENABLED=$(systemctl list-unit-files --state=enabled | grep -c $SERVICE_NAME);
    if [ "$COUNT_SERVICE_ENABLED" -gt "0" ]; then
        set +e
        RUNNING_SERVICE=$(systemctl is-active --quiet $SERVICE_NAME > /dev/null 2>&1; echo $?);
        set -e
        if [ "$RUNNING_SERVICE" -eq "0" ]; then
            echo "Service $SERVICE_NAME is running: stop it.";
            systemctl stop "$SERVICE_NAME"
        fi
        echo "Service $SERVICE_NAME is enabled: disable it.";
        systemctl disable "$SERVICE_NAME"
        systemctl daemon-reload
    fi
else
    echo "This script don't run as root: ignore systemctl checks and disable actions";
fi


##########
# USER ADD
##########
USER_HOME_DIR="$ROOT/var/lib/$APP_NAME";

if [ -f "$CURRENT_APP_RUNAS_FILE" ]; then
    SERVICE_USER_NAME=$(cat "$CURRENT_APP_RUNAS_FILE");
else
    if [ "$EUID" -eq 0 ]; then
        SERVICE_USER_NAME="$SERVICE_NAME";
    else
        SERVICE_USER_NAME="$USER";
    fi
    read -rp "Enter the username to run $APP_NAME: [$SERVICE_USER_NAME]: " linuxusrname
    SERVICE_USER_NAME=${linuxusrname:-$SERVICE_USER_NAME}
fi

echo "This app will run as $SERVICE_USER_NAME user (to change this, update $CURRENT_APP_RUNAS_FILE and restart setup)";
echo "$SERVICE_USER_NAME" > "$CURRENT_APP_RUNAS_FILE";

if [ "$EUID" -eq 0 ]; then
    set +e
    USER_EXISTS=$(id -u "$SERVICE_USER_NAME" > /dev/null 2>&1; echo $?);
    set -e
    if [ "$USER_EXISTS" -gt "0" ]; then
        echo "Create user $SERVICE_USER_NAME";
        useradd -d "$USER_HOME_DIR" -m -r -s /bin/false "$SERVICE_USER_NAME"
    else
        mkdir -p "$USER_HOME_DIR"
        chown -R "$SERVICE_USER_NAME" "$USER_HOME_DIR"
    fi
else
    echo "This script don't run as root: ignore useradd/chown actions";
fi

########################
# GET/SET DATABASE CREDS
########################

DB_VAR_dbserver="";
DB_VAR_dbname="";
DB_VAR_dbusername="";
DB_VAR_dbuserpassword="";
DB_VAR_dbport="";
DB_VAR_dburl="";
DB_VAR_dbdriver="";
DB_VAR_dbdialect="";

if [ -f "$DATABASE_CHANGELOG" ]; then
    CURRENT_DATABASE_CREDS_FILE="$CONF_DIR/database-credentials.inc.sh";
    if [ ! -f "$CURRENT_DATABASE_CREDS_FILE" ]; then
        echo "";
        echo "Let's now setup database configuration and credentials"
        read -rp "Enter the database server hostname/IP address [localhost]: " dbserver
        dbserver=${dbserver:-"localhost"}

        read -rp "Enter the database server TCP port [3306]: " dbport
        dbport=${dbport:-3306}

        read -rp "Enter the database name [$APP_NAME]: " dbname
        dbname=${dbname:-$APP_NAME}

        read -rp "Enter the database server username [$SERVICE_USER_NAME]: " dbusername
        dbusername=${dbusername:-$SERVICE_USER_NAME}

        DEFAULT_URL="jdbc:mysql://$dbserver:$dbport/$dbname?useSSL=false&useLegacyDatetimeCode=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
        read -rp "Enter the database JDBC URL [$DEFAULT_URL]: " dburl
        dburl=${dburl:-$DEFAULT_URL}

        read -rsp "Enter the database server user password: " dbuserpassword
        echo "";

        read -rp "Enter the JDBC driver [com.mysql.cj.jdbc.Driver]: " dbdriver
        dbdriver=${dbdriver:-"com.mysql.cj.jdbc.Driver"}

        read -rp "Enter the Hibernate dialect [org.hibernate.dialect.MySQL8Dialect]: " dbdialect
        dbdialect=${dbdialect:-"org.hibernate.dialect.MySQL8Dialect"}

        {
            echo "# This file is autogenerated by $APP_NAME setup, free feel to edit"
            echo "DB_VAR_dbserver=\"$dbserver\"";
            echo "DB_VAR_dbname=\"$dbname\"";
            echo "DB_VAR_dbusername=\"$dbusername\"";
            echo "DB_VAR_dbuserpassword=\"$dbuserpassword\"" ;
            echo "DB_VAR_dbport=\"$dbport\"";
            echo "DB_VAR_dburl=\"$dburl\"";
            echo "DB_VAR_dbdriver=\"$dbdriver\"";
            echo "DB_VAR_dbdialect=\"$dbdialect\"";
        } > "$CURRENT_DATABASE_CREDS_FILE"
        echo "Please edit $CURRENT_DATABASE_CREDS_FILE to change this values (if needed), and restart this script after."
    fi

    echo "Database setup is now stored in $CURRENT_DATABASE_CREDS_FILE";

    chmod 600 "$CURRENT_DATABASE_CREDS_FILE"
    if [ "$EUID" -eq 0 ]; then
        chown root:root "$CURRENT_DATABASE_CREDS_FILE"
    fi
    . "$CURRENT_DATABASE_CREDS_FILE"
fi

###########
# PUT CONFS
###########
CURRENT_APP_CONF="$CONF_DIR/application.yml";

if [ -f "$CURRENT_APP_CONF" ]; then
    echo "Copy a new example of the actual application configuration file to $CURRENT_APP_CONF-new.";
    install --owner="$SERVICE_USER_NAME" --mode=0644 \
        "$BASE_DIR/application.yml" "$CURRENT_APP_CONF-new"
else
    echo "Copy an application configuration file to $CURRENT_APP_CONF (edit it if needed).";
    install --owner="$SERVICE_USER_NAME" --mode=0600 \
        "$BASE_DIR/application.yml" "$CURRENT_APP_CONF"
    $JAVA \
        -Dreplace.DATABASE_SERVER="$DB_VAR_dbserver" \
        -Dreplace.DATABASE_NAME="$DB_VAR_dbname" \
        -Dreplace.DATABASE_USER="$DB_VAR_dbusername" \
        -Dreplace.DATABASE_PASSWORD="$DB_VAR_dbuserpassword" \
        -Dreplace.DATABASE_PORT="$DB_VAR_dbport" \
        -Dreplace.DATABASE_URL="$DB_VAR_dburl" \
        -Dreplace.DATABASE_DRIVER="$DB_VAR_dbdriver" \
        -Dreplace.DATABASE_DIALECT="$DB_VAR_dbdialect" \
        "$BASE_DIR/set-file-vars.java" \
        "$CURRENT_APP_CONF"
fi

CURRENT_LOG_CONF="$CONF_DIR/log4j2.xml";
if [ -f "$CURRENT_LOG_CONF" ]; then
    echo "Copy a new example of the Log4j2 configuration file to $CURRENT_LOG_CONF-new.";
    install --owner="$SERVICE_USER_NAME" --mode=0644 \
        "$BASE_DIR/log4j2.xml" "$CURRENT_LOG_CONF-new"
else
    echo "Copy an Log4j2 configuration file to $CURRENT_LOG_CONF (edit it if needed).";
    install --owner="$SERVICE_USER_NAME" --mode=0640 \
        "$BASE_DIR/log4j2.xml" "$CURRENT_LOG_CONF"
    $JAVA \
        -Dreplace.CONFIGURED_ROOT="$ROOT" \
        -Dreplace.APPLICATION_NAME="$APP_NAME" \
        "$BASE_DIR/set-file-vars.java" \
        "$CURRENT_LOG_CONF"
fi

LOG_DIR="$ROOT/var/log/$APP_NAME";
echo "Create/refresh log directory $LOG_DIR";
mkdir -p "$LOG_DIR"
chown -R "$SERVICE_USER_NAME" "$LOG_DIR"
chmod -R 750 "$LOG_DIR"

###############
# PUT NEWER JAR
###############
JAR_NAME="springboot.jar";
echo "Copy the new jar file to $LIB_DIR/$JAR_NAME.";
install --owner="$SERVICE_USER_NAME" --mode=0644 --backup=never --suffix="-old" \
    "$BASE_DIR/$JAR_NAME" "$LIB_DIR/"

###############
# RUN LIQUIBASE
###############
if [ -f "$DATABASE_CHANGELOG" ]; then
    if [ "${SKIP_LIQUIBASE:-"0"}" = "1" ]; then
        echo "Skip Liquibase update";
    elif ! [ -x "$(command -v liquibase)" ]; then
        echo "Error: liquibase is not installed." >&2
        echo "Skip database update..." >&2;
    else
        echo "Start Liquibase automatic update";
        liquibase \
            --username="$DB_VAR_dbusername" \
            --password="$DB_VAR_dbuserpassword" \
            --url="$DB_VAR_dburl" \
            --driver="$DB_VAR_dbdriver" \
            --changeLogFile="$BASE_DIR/database-changelog.xml" \
            update
    fi
fi

##########################
# PREPARE DEFAULT MANIFEST
##########################

SYSTEMD_SERVICE_MANIFEST="$SYSTEMD_DIR/$SERVICE_NAME.service";
LIB_SERVICE_MANIFEST="$LIB_DIR/$SERVICE_NAME.service";
SERVICE_ENABLE_SCRIPT="$LIB_DIR/$SERVICE_NAME-enable";
SERVICE_DISABLE_SCRIPT="$LIB_DIR/$SERVICE_NAME-disable";
SERVICE_START_SCRIPT="$LIB_DIR/$SERVICE_NAME-start";
SERVICE_STOP_SCRIPT="$LIB_DIR/$SERVICE_NAME-stop";
SERVICE_STATUS_SCRIPT="$LIB_DIR/$SERVICE_NAME-status";

$JAVA \
    -Dreplace.APPLICATION_NAME="$APP_NAME" \
    -Dreplace.LIB_SVC_FILE="$LIB_SERVICE_MANIFEST" \
    -Dreplace.SYSD_SVC_FILE="$SYSTEMD_SERVICE_MANIFEST" \
    -Dreplace.SVC_ENABLE="$SERVICE_ENABLE_SCRIPT" \
    -Dreplace.SVC_DISABLE="$SERVICE_DISABLE_SCRIPT" \
    -Dreplace.SVC_START="$SERVICE_START_SCRIPT" \
    -Dreplace.SVC_STOP="$SERVICE_STOP_SCRIPT" \
    -Dreplace.SVC_STATUS="$SERVICE_STATUS_SCRIPT" \
    -Dreplace.SVC_NAME="$SERVICE_NAME" \
    -Dreplace.SVC_USER_NAME="$SERVICE_USER_NAME" \
    -Dreplace.APP_JAR_FILE="$LIB_DIR/$JAR_NAME" \
    -Dreplace.DUMP_DIR="$USER_HOME_DIR" \
    -Dreplace.LOG_DIR="$LOG_DIR" \
    -Dreplace.ETC_CONF_FILE="$CURRENT_APP_CONF" \
    -Dreplace.ETC_CONF_LOG="$CURRENT_LOG_CONF" \
    "$BASE_DIR/set-file-vars.java" \
    "$BASE_DIR/default.sh"

set +e
DEFAULT_SAME=$(cmp --silent "$BASE_DIR/default.sh" "$DEFAULT_FILE" > /dev/null 2>&1; echo $?);
set -e

if [ "$DEFAULT_SAME" -gt "0" ]; then
    echo "Replace the default file to $DEFAULT_FILE";
    install --owner="$USER" --group="$USER" --mode=0644 --backup=never --suffix="-previous" \
        "$BASE_DIR/default.sh" "$DEFAULT_FILE"
fi

#########################
# PREPARE SYSTEMD SCRIPTS
#########################

echo "Install service tools";
$JAVA -Dreplace.DEFAULT_FILE="$DEFAULT_FILE" "$BASE_DIR/set-file-vars.java" "$BASE_DIR/systemd-service-enable.bash"
$JAVA -Dreplace.DEFAULT_FILE="$DEFAULT_FILE" "$BASE_DIR/set-file-vars.java" "$BASE_DIR/systemd-service-disable.bash"
$JAVA -Dreplace.DEFAULT_FILE="$DEFAULT_FILE" "$BASE_DIR/set-file-vars.java" "$BASE_DIR/systemd-service-start.bash"
$JAVA -Dreplace.DEFAULT_FILE="$DEFAULT_FILE" "$BASE_DIR/set-file-vars.java" "$BASE_DIR/systemd-service-stop.bash"
$JAVA -Dreplace.DEFAULT_FILE="$DEFAULT_FILE" "$BASE_DIR/set-file-vars.java" "$BASE_DIR/systemd-service-status.bash"

install --owner="$USER" --group="$USER" --mode=0754 "$BASE_DIR/systemd-service-enable.bash" "$SERVICE_ENABLE_SCRIPT"
install --owner="$USER" --group="$USER" --mode=0754 "$BASE_DIR/systemd-service-disable.bash" "$SERVICE_DISABLE_SCRIPT"
install --owner="$USER" --group="$USER" --mode=0754 "$BASE_DIR/systemd-service-start.bash" "$SERVICE_START_SCRIPT"
install --owner="$USER" --group="$USER" --mode=0754 "$BASE_DIR/systemd-service-stop.bash" "$SERVICE_STOP_SCRIPT"
install --owner="$USER" --group="$USER" --mode=0754 "$BASE_DIR/systemd-service-status.bash" "$SERVICE_STATUS_SCRIPT"

ln -sf "$SERVICE_ENABLE_SCRIPT" "$BIN_DIR/"
ln -sf "$SERVICE_DISABLE_SCRIPT" "$BIN_DIR/"
ln -sf "$SERVICE_START_SCRIPT" "$BIN_DIR/"
ln -sf "$SERVICE_STOP_SCRIPT" "$BIN_DIR/"
ln -sf "$SERVICE_STATUS_SCRIPT" "$BIN_DIR/"

$JAVA \
    -Dreplace.APPLICATION_NAME="$MVN_VAR_name" \
    -Dreplace.MVN_VAR_description="$MVN_VAR_description" \
    -Dreplace.MVN_VAR_organization_url="$MVN_VAR_organization_url" \
    -Dreplace.DEFAULT_ENV_FILE="$DEFAULT_FILE" \
    -Dreplace.WORK_DIR="$USER_HOME_DIR" \
    -Dreplace.JAVA_BIN="$JAVA" \
    -Dreplace.SVCNAME="$SERVICE_NAME" \
    -Dreplace.SERVICE_USER_NAME="$SERVICE_USER_NAME" \
    -Dreplace.SERVICE_GRP_NAME="$SERVICE_USER_NAME" \
    "$BASE_DIR/set-file-vars.java" \
    "$BASE_DIR/systemd.service"

echo "Prepare SystemD service manifest";
install --owner="$USER" --group="$USER" --mode=0755 "$BASE_DIR/systemd.service" "$LIB_SERVICE_MANIFEST"

echo $MVN_VAR_version > "$CURRENT_APP_VERSION_FILE"

echo "";
echo "$MVN_VAR_name service is now deployed."
echo "";
echo "You can run it manually with:"
echo "runuser -u $SERVICE_USER_NAME -- $JAVA -Dlogging.config=$CURRENT_LOG_CONF -jar $LIB_DIR/$JAR_NAME --spring.config.location=$CURRENT_APP_CONF";
echo "";
echo "You can use SystemD scripts for register service with $SERVICE_NAME-enable";
echo "And start it with $SERVICE_NAME-start";
echo "Use $SERVICE_NAME-stop / $SERVICE_NAME-disable / $SERVICE_NAME-status"
echo "";