#!/bin/bash
# shellcheck disable=SC1091
set -eu
. DEFAULT_FILE
if [ ! -f "$SYSTEMD_SERVICE_MANIFEST" ]; then
	echo "$APP_NAME service script ($SYSTEMD_SERVICE_MANIFEST) is not installed."
	exit 0;
fi
systemctl stop "$SERVICE_NAME"
$SERVICE_STATUS_SCRIPT
