#!/usr/bin/env bash

set -euo pipefail

SOURCE_PATH_CONFIG="$1/config"; [ -d "$SOURCE_PATH_CONFIG" ] || { echo "'$SOURCE_PATH_CONFIG' not found."; exit 1; }
SOURCE_PATH_PROVISIONING="$1/provisioning"; [ -d "$SOURCE_PATH_PROVISIONING" ] || { echo "'$SOURCE_PATH_PROVISIONING' not found."; }
TARGET_PATH_CONFIG="/habitat-config/target/mariadb/config"
TARGET_PATH_PROVISIONING="/habitat-config/target/mariadb/provisioning"

echo "Cleaning previous configuration at '$TARGET_PATH_CONFIG'"
rm -rf "${TARGET_PATH_CONFIG:?}/"{*,.*} &>/dev/null
echo "Copying new configuration to '$TARGET_PATH_CONFIG'"
cp -rp "$SOURCE_PATH_CONFIG/." "$TARGET_PATH_CONFIG/"

[ -d "$SOURCE_PATH_PROVISIONING" ] && {
    echo "Cleaning previous configuration at '$TARGET_PATH_PROVISIONING'"
    rm -rf "${TARGET_PATH_PROVISIONING:?}/"{*,.*} &>/dev/null
    echo "Copying new configuration to '$TARGET_PATH_PROVISIONING'"
    cp -rp "$SOURCE_PATH_PROVISIONING/." "$TARGET_PATH_PROVISIONING/"
}

exit 0