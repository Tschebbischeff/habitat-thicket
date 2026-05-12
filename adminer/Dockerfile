FROM adminer:latest

USER root
#
# RUN apk -U add gosu

COPY ./entrypoint-hook.sh /entrypoint-hook.sh
RUN chmod +x /entrypoint-hook.sh
RUN chown adminer:adminer /entrypoint-hook.sh

USER adminer

ENTRYPOINT ["/entrypoint-hook.sh", "docker-php-entrypoint"]
CMD	[ "php", "-S", "[::]:8080", "-t", "/var/www/html" ]