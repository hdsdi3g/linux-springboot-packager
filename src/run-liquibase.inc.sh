#!/bin/bash

if [ ! -x "$(command -v liquibase)" ]; then
    echo "Error: liquibase is not installed." >&2
    echo "Skip database update..." >&2;
    echo "See on man @SERVICE_NAME@ how-to run it manually." >&2;
elif [ ! -f "@OUTPUT_LIQUIBASECREDS_FILE@" ]
    echo "Can't found liquibase credentials in @OUTPUT_LIQUIBASECREDS_FILE@."
    echo "Please run sudo bash @OUTPUT_LIQUIBASESCRIPTCREDS_FILE@ for set it after.";
    echo "But for now, skip database update...";
    echo "More information on man @SERVICE_NAME@." >&2;
else
    echo "Start Liquibase automatic update for @NAME@...";
    . "@OUTPUT_LIQUIBASECREDS_FILE@";
    liquibase \
        --username="$dbusername" \
        --password="$dbuserpassword" \
        --url="$dburl" \
        --driver="$dbdriver" \
        --changeLogFile="@OUTPUT_LIQUIBASEXML_FILE@" \
        update
fi
