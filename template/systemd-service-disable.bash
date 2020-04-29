#!/bin/bash
# shellcheck disable=SC1091
set -eu
. DEFAULT_FILE
$SERVICE_STOP_SCRIPT
systemctl disable "$SERVICE_NAME"
systemctl daemon-reload
rm -f "$SYSTEMD_SERVICE_MANIFEST"
echo "$APP_NAME service removed from $SYSTEMD_SERVICE_MANIFEST"
