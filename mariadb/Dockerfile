FROM mariadb:lts

COPY ./entrypoint-hook.sh /entrypoint-hook.sh
RUN chmod +x /entrypoint-hook.sh

CMD ["/entrypoint-hook.sh", "mariadb"]