#!/bin/bash
# shellcheck disable=SC1091
set -eu
. DEFAULT_FILE
install --owner=root --group=root --mode=0755 "$LIB_SERVICE_MANIFEST" "$SYSTEMD_SERVICE_MANIFEST"
systemctl enable "$SYSTEMD_SERVICE_MANIFEST"
systemctl daemon-reload
echo "$APP_NAME Service installed in $SYSTEMD_SERVICE_MANIFEST"
echo "Use $SERVICE_START_SCRIPT or systemctl start $SERVICE_NAME for start $APP_NAME service"
