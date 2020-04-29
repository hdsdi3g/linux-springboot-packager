#!/bin/bash

set -eu

cd "$(dirname "$0")"

if [ ! -d packages ]; then
	echo "No package to extract, close script"
	exit 0;
fi

EXPORT_DIR=$(realpath "packages/_export");
if [ -d "$EXPORT_DIR" ]; then
	rm -rf "$EXPORT_DIR";
fi
mkdir -p "$EXPORT_DIR"

ALL_PACKAGES=$(find packages -maxdepth 1 -type f -name "*.run.sh");

RUN_PACKAGE="0";
if [ "$#" -eq 1 ]; then
    RUN_PACKAGE=$1;
fi

for PKG_FILE in $ALL_PACKAGES;
do
	BASE_PACKAGE_NAME=$(basename "$PKG_FILE");
	if [ "$RUN_PACKAGE" = "1" ]; then
		echo "Run: $PKG_FILE -- -chroot $EXPORT_DIR/$BASE_PACKAGE_NAME"
		$PKG_FILE -- -chroot "$EXPORT_DIR/$BASE_PACKAGE_NAME";
	else
		echo "Export $BASE_PACKAGE_NAME in $EXPORT_DIR";
		$PKG_FILE --noexec --keep --target "$EXPORT_DIR/$BASE_PACKAGE_NAME"
	fi
done
