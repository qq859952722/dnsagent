#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/cron_service_check.log"

logging() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

logging "Runit service status check started"

for service in /etc/service/adguarddns /etc/service/smartdns /etc/service/dnscrypt-proxy /etc/service/cron; do
    if [ -d "$service" ]; then
        logging "Service status for ${service##*/}:"
        sv status "$service" >> "$LOG_FILE" 2>&1 || logging "Failed to query status for ${service##*/}"
    else
        logging "Service directory $service not found"
    fi
done

logging "Runit service status check finished"
