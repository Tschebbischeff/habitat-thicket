#!/bin/sh

echo "Customized entrypoint started."

# Execute in background before trying to provision
"$@" &

# Wait for database to be initialized
echo "Waiting for MariaDB to initialize."
while ! healthcheck.sh --connect --innodb_initialized >/dev/null 2>/dev/null; do
    sleep 5
done

exec_upgrade() {
    file="$1"
    case "${file##*.}" in
        sql)
            mariadb -u root --password="$MARIADB_ROOT_PASSWORD" <"$file"
            return "$?"
        ;;
        sh)
            if [ -x "$file" ]; then
                "$file"
                return "$?"
            else
                # shellcheck disable=SC1090 # File existence has been checked
                . "$file"
                return "$?"
            fi
        ;;
    esac
    return 1
}

exec_upgrade_if_exists() {
    if [ -f "./$1/$2.sql" ]; then
        exec_upgrade "./$1/$2.sql"
        return "$?"
    elif [ -f "./$1/$2.sh" ]; then
        exec_upgrade "./$1/$2.sh"
        return "$?"
    fi
    return 0
}

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
            Version INT NOT NULL
        );
EOF
    for appName in ./*; do
        [ -d "$appName" ] || continue
        appName="${appName#./}"
        # shellcheck disable=SC2016 # Using backticks inside single quotes is intentional
        currentSqlVersion="$(mariadb -u root --password="$MARIADB_ROOT_PASSWORD" "habitat_metadata" -NBe 'SELECT `Version` FROM `HabitatApps` WHERE `Name` = "'"$appName"'";')"
        if [ -z "$currentSqlVersion" ]; then
            echo "App '$appName' is not registered yet, initializing..."
            if exec_upgrade_if_exists "$appName" ".dbinit"; then
                echo "Initialization successful."
                # shellcheck disable=SC2016 # Using backticks inside single quotes is intentional
                mariadb -u root --password="$MARIADB_ROOT_PASSWORD" "habitat_metadata" -e 'INSERT INTO `HabitatApps` (`Name`, `Version`) VALUES ("'"$appName"'", 0);'
                currentSqlVersion="0"
            else
                echo "Initialization failed. Continuing with next app."
                continue
            fi
        else
            echo "App '$appName' is registered and currently on version '$currentSqlVersion'."
        fi
        migrations=$(
            for file in "./$appName"/*; do
                [ -e "$file" ] || continue
                extension="${file##*.}"
                [ "$extension" = "sql" ] || [ "$extension" = "sh" ] || continue
                forVersion="$(basename "${file%.*}")"
                [ "$forVersion" -gt "$currentSqlVersion" ] && echo "${forVersion}.${extension}"
            done | sort -t. -k1,1n
        )
        [ -n "$migrations" ] || {
            echo "App '$appName' is already up-to-date."
            continue
        }
        for file in $migrations; do
            toVersion="${file%.*}"
            echo "Upgrading app '$appName' to version '$toVersion'..."
            # shellcheck disable=SC1090 # File existence has been checked
            if exec_upgrade "./$appName/$file"; then
                echo "Upgrade successful."
                # shellcheck disable=SC2016 # Using backticks inside single quotes is intentional
                mariadb -u root --password="$MARIADB_ROOT_PASSWORD" "habitat_metadata" -e 'UPDATE `HabitatApps` SET `Version`='"$toVersion"' WHERE `Name`="'"$appName"'";'
            else
                echo "Upgrade failed. Continuing with next app."
                break
            fi
        done
        exec_upgrade_if_exists "$appName" ".always"
    done
fi

echo "Provisioning of MariaDB done, waiting for container exit..."
# shellcheck disable=SC2046 # Word splitting intentional
wait $(jobs -p)
echo "Container exited, goodbye."