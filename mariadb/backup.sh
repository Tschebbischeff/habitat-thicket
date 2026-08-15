#!/usr/bin/env bash

MARIADB_ROOT_PASSWORD="$(cat "/run/secrets/MARIADB_ROOT_PASSWORD")"

export ANY_FAILURE=""
BASE_PATH="/var/lib/mysql"
RETENTION_DAYS="${MARIADB_BACKUP_RETENTION_DAYS:-2}"
BACKUP_DIR="/backups/$(basename "$BASE_PATH")/$(TZ="UTC" date +"%Y-%m-%dT%H:%M:%SZ")"
mkdir -p "$BACKUP_DIR"
chmod 755 "/backups/$(basename "$BASE_PATH")"
chmod 755 "$BACKUP_DIR"

backupFailed() {
    ANY_FAILURE="_"
    originStage="$1"; shift
    originExitCode="$1"; shift
    echo "Backup of database failed during stage '$originStage' with exit code '$originExitCode', continuing to next file..."
}

echo "Starting backup of '$BASE_PATH' to '$BACKUP_DIR'..."

mariadb-backup --backup \
    --target-dir="$BACKUP_DIR" \
    --host=localhost --port=3306 \
    -u "root" --password="$MARIADB_ROOT_PASSWORD"
exitCode="$?"; [ "$exitCode" -ne "0" ] && backupFailed "backup" "$exitCode"

mariadb-backup --prepare \
    --target-dir="$BACKUP_DIR"
exitCode="$?"; [ "$exitCode" -ne "0" ] && backupFailed "prepare" "$exitCode"

echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "/backups/$(basename "$BASE_PATH")" -mindepth 1 -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" -exec rm -rf {} +

{ [ -z "$ANY_FAILURE" ] && echo "Backup job completed successfully."; } || { echo "Backup job caused errors." && exit 1; }
