#!/usr/bin/env bash

set -euo pipefail

SOURCE_PATH_CONFIG="$1/config"; [ -d "$SOURCE_PATH_CONFIG" ] || { echo "'$SOURCE_PATH_CONFIG' not found."; exit 1; }
SOURCE_PATH_INITDB="$1/initdb"; [ -d "$SOURCE_PATH_INITDB" ] || { echo "'$SOURCE_PATH_INITDB' not found."; exit 1; }
TARGET_PATH_CONFIG="/habitat-config/target/mariadb/config"
TARGET_PATH_INITDB="/habitat-config/target/mariadb/initdb"

echo "Cleaning previous configuration at '$TARGET_PATH_CONFIG'"
rm -rf "${TARGET_PATH_CONFIG:?}/"{*,.*} &>/dev/null
echo "Copying new configuration to '$TARGET_PATH_CONFIG'"
cp -rp "$SOURCE_PATH_CONFIG/." "$TARGET_PATH_CONFIG/"

echo "Cleaning previous configuration at '$TARGET_PATH_INITDB'"
rm -rf "${TARGET_PATH_INITDB:?}/"{*,.*} &>/dev/null
echo "Copying new configuration to '$TARGET_PATH_INITDB'"
cp -rp "$SOURCE_PATH_INITDB/." "$TARGET_PATH_INITDB/"

exit 0