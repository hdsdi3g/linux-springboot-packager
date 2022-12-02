#!/bin/bash

COUNT_SERVICE_PRESENCE=$(systemctl list-unit-files | grep -c @SERVICE_NAME@);
if [ "$COUNT_SERVICE_PRESENCE" -gt "0" ]; then
    RUNNING_SERVICE=$(systemctl is-active --quiet @SERVICE_NAME@ > /dev/null 2>&1; echo $?);
    if [ "$RUNNING_SERVICE" -eq "0" ]; then
        echo "Service @SERVICE_NAME@ is running: stop it.";
        systemctl stop "@SERVICE_NAME@"
    fi
fi
