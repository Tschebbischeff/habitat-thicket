#!/bin/sh

echo "Customized entrypoint started."

exec "$@"

# Execute in background before trying to provision
"$@" &

# Wait for database to be initialized
echo "Waiting for MariaDB to initialize."
while ! healthcheck.sh --connect --innodb_initialized >/dev/null; do
    sleep 5
done

echo "Starting provisioning of MariaDB..."
if [ -d "/mariadb-provisioning" ]; then
    cd "/mariadb-provisioning" || exit 1
    MARIADB_ROOT_PASSWORD="$(cat "/run/secrets/MARIADB_ROOT_PASSWORD")"
    # Metadata database first
    mariadb -u root --password="$MARIADB_ROOT_PASSWORD" <<'EOF'
        CREATE DATABASE IF NOT EXISTS `habitat_metadata`;
        USE `habitat_metadata`;
        CREATE TABLE IF NOT EXISTS `HabitatApps` (
            ID INT AUTO_INCREMENT PRIMARY KEY,
            Name VARCHAR(255) NOT NULL UNIQUE,
            Version VARCHAR(50) NOT NULL
        );
EOF
    for appName in ./*; do
        [ -d "$appName" ] || continue
        appName="${appName#./}"
        # shellcheck disable=SC2016 # Using backticks inside single quotes is intentional
        currentSqlVersion="$(mariadb -u root --password="$MARIADB_ROOT_PASSWORD" "habitat_metadata" -NBe 'SELECT `Version` FROM `HabitatApps` WHERE `Name` = "'"$appName"'";')"
        if [ -z "$currentSqlVersion" ]; then
            echo "App '$appName' is not registered yet, initializing..."
            if [ -f "./$appName/.dbinit.sql" ]; then
                mariadb -u root --password="$MARIADB_ROOT_PASSWORD" <"./$appName/.dbinit.sql"
            fi
            # shellcheck disable=SC2016 # Using backticks inside single quotes is intentional
            mariadb -u root --password="$MARIADB_ROOT_PASSWORD" "habitat_metadata" -e 'INSERT INTO `HabitatApps` (`Name`, `Version`) VALUES ("'"$appName"'", "0");'
            currentSqlVersion="0"
        else
            echo "App '$appName' is registered and currently on version '$currentSqlVersion'."
        fi
        migrations=$(
            for sqlFile in "./$appName"/*.sql; do
                [ -e "$sqlFile" ] || continue
                forVersion="$(basename "${sqlFile%.*}")"
                [ "$forVersion" -gt "$currentSqlVersion" ] && echo "${forVersion}.sql"
            done | sort -t. -k1,1n
        )
        [ -n "$migrations" ] || {
            echo "App '$appName' is already up-to-date."
            continue
        }
        for sqlFile in $migrations; do
            toVersion="${sqlFile%.*}"
            echo "Upgrading app '$appName' to version '$toVersion'..."
            if mariadb -u root --password="$MARIADB_ROOT_PASSWORD" <"./$appName/$sqlFile"; then
                # shellcheck disable=SC2016 # Using backticks inside single quotes is intentional
                mariadb -u root --password="$MARIADB_ROOT_PASSWORD" "habitat_metadata" -e 'UPDATE `HabitatApps` SET `Version`="'"$toVersion"'" WHERE `Name`="'"$appName"'";'
            else
                echo "Upgrade failed. Continuing with next app."
                break
            fi
        done
    done
fi

echo "Provisioning of MariaDB done, waiting for container exit..."
# shellcheck disable=SC2046 # Word splitting intentional
wait $(jobs -p)