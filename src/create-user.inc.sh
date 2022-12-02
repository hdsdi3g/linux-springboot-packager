#!/bin/bash

# CREATE USER ONLY IF NOT EXISTS

USER_EXISTS=$(id -u "@SERVICE_USER_NAME@" > /dev/null 2>&1; echo $?);
if [ "$USER_EXISTS" -gt "0" ]; then
    echo "Create group @SERVICE_USER_NAME@"
    groupadd -r "@SERVICE_USER_NAME@"
    echo "Create user @SERVICE_USER_NAME@";
    useradd -d "@USER_HOME_DIR@" -m -g "@SERVICE_USER_NAME@" -r -s /bin/false "@SERVICE_USER_NAME@"
else
    mkdir -p "@USER_HOME_DIR@"
    chown -R "@SERVICE_USER_NAME@:@SERVICE_USER_NAME@" "@USER_HOME_DIR@"
fi
