FROM mariadb:lts

RUN apt update && apt install -y cron grep; rm -rf /var/lib/apt/lists/*

COPY ./backup.sh /backup.sh
RUN chmod +x /backup.sh

COPY ./entrypoint-hook.sh /entrypoint-hook.sh
RUN chmod +x /entrypoint-hook.sh

ENTRYPOINT ["/entrypoint-hook.sh"]
CMD ["docker-entrypoint.sh", "mariadbd"]