#!/usr/bin/env bash

MARIADB_ROOT_PASSWORD="$(cat "/run/secrets/MARIADB_ROOT_PASSWORD")"
mariadb-upgrade -u root --password="$MARIADB_ROOT_PASSWORD"