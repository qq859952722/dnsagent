#!/bin/bash

set -e

CONFIG_DIR="/config"
BACKUP_DIR="/back"

mkdir -p "$CONFIG_DIR"

for app in adguarddns smartdns dnscrypt-proxy; do
    if [ ! -d "$CONFIG_DIR/$app" ]; then
        echo "Initializing $app configuration..."
        cp -r "$BACKUP_DIR/$app" "$CONFIG_DIR/"
    fi
done

UPDATE_LISTS_ON_START=${UPDATE_LISTS_ON_START:-false}
UPDATE_LISTS_CRON=${UPDATE_LISTS_CRON:-"0 3 * * 0"}

if [ "$UPDATE_LISTS_ON_START" = "true" ]; then
    echo "Updating lists on start..."
    /usr/local/bin/update-lists.sh || true
fi

if [ -n "$UPDATE_LISTS_CRON" ]; then
    echo "Setting up cron job for list updates: $UPDATE_LISTS_CRON"
    echo "$UPDATE_LISTS_CRON /usr/local/bin/update-lists.sh >> /var/log/update-lists.log 2>&1" > /etc/cron.d/update-lists
    crontab /etc/cron.d/update-lists
    cron
fi

echo "Starting runit services..."
exec runsvdir -P /etc/runit
