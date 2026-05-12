#!/bin/sh

# Based on: https://github.com/TimWolla/docker-adminer/blob/master/5/entrypoint.sh

set -e

echo "Customized entrypoint started."

if [ -n "$ADMINER_DESIGN" ]; then
	# Only create link on initial start, to ensure that explicit changes to
	# adminer.css after the container was started once are preserved.
	if [ ! -e .adminer-init ]; then
        [ -f "designs/$ADMINER_DESIGN/adminer.css" ] && ln -sf "designs/$ADMINER_DESIGN/adminer.css" .
        [ -f "designs/$ADMINER_DESIGN/adminer-dark.css" ] && ln -sf "designs/$ADMINER_DESIGN/adminer-dark.css" .
	fi
fi

number=1
for PLUGIN in $ADMINER_PLUGINS; do
    rm -f "plugins-enabled/*.php"
    if [ -f "plugins-provided/$PLUGIN.php" ]; then
        cp -f "plugins-provided/$PLUGIN.php" "plugins-enabled/$(printf "%03d" $number)-$PLUGIN.php"
    else
	    php plugin-loader.php "$PLUGIN" >"plugins-enabled/$(printf "%03d" $number)-$PLUGIN.php"
    fi
	number="$(( number + 1 ))"
done

echo "Plugins enabled:"
ls -la plugins-enabled

# chown -R adminer:adminer /var/www/html

touch .adminer-init || true

# exec gosu adminer "$@"
exec "$@"