#!/bin/bash

# 0 remove
# 1 install
# 1 upgrade old uninstall
# 2 upgrade new install

if [ "$1" -eq "0" ]; then
    # 0 remove
    COUNT_SERVICE_ENABLED=$(systemctl list-unit-files --state=enabled | grep -c @SERVICE_NAME@);
    if [ "$COUNT_SERVICE_ENABLED" -gt "0" ]; then
        echo "Service @SERVICE_NAME@ is enabled: disable it.";
        systemctl disable "@SERVICE_NAME@"
    fi
    if [ -f "@OUTPUT_SERVICE_LINK@" ]; then
        rm -f "@OUTPUT_SERVICE_LINK@";
        systemctl daemon-reload
    fi
fi
