FROM adminer:latest

RUN apk -U add gosu

COPY ./entrypoint-hook.sh /entrypoint-hook.sh
RUN chmod +x /entrypoint-hook.sh

USER root
ENTRYPOINT ["/entrypoint-hook.sh"]