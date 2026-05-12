#!/usr/bin/env bash

set -euo pipefail

SOURCE_PATH_PLUGINS="$1/plugins"; [ -d "$SOURCE_PATH_PLUGINS" ] || { echo "'$SOURCE_PATH_PLUGINS' not found."; exit 1; }
TARGET_PATH_PLUGINS="/habitat-config/target/adminer/plugins"

echo "Cleaning previous configuration at '$TARGET_PATH_PLUGINS'"
rm -rf "${TARGET_PATH_PLUGINS:?}/"{*,.*} &>/dev/null
echo "Copying new configuration to '$TARGET_PATH_PLUGINS'"
cp -rp "$SOURCE_PATH_PLUGINS/." "$TARGET_PATH_PLUGINS/"

exit 0