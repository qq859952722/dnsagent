#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/cron_update_list.log"

logging() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

logging "Weekly list update task started"

# Update rule lists directly into /config/smartdns/list
if /bin/init.sh download_rule_lists /config/smartdns/list; then
    logging "Rule list update completed successfully"
    if sv restart /etc/service/smartdns >> "$LOG_FILE" 2>&1; then
        logging "smartdns service restarted successfully"
    else
        logging "Failed to restart smartdns service"
    fi
else
    logging "Rule list update failed"
fi

logging "Weekly list update task finished"
