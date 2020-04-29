#!/bin/bash
# shellcheck disable=SC1091
set -eu
. DEFAULT_FILE
if [ ! -f "$SYSTEMD_SERVICE_MANIFEST" ]; then
	$SERVICE_ENABLE_SCRIPT
fi
systemctl start "$SERVICE_NAME"
$SERVICE_STATUS_SCRIPT
