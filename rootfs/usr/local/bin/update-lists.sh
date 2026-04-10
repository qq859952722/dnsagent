#!/bin/bash

set -e

LIST_DIR="/config/smartdns/list"
mkdir -p "$LIST_DIR"

update_success=0

update_file() {
    local filename="$1"
    shift
    local urls=("$@")
    local filepath="$LIST_DIR/$filename"
    local temp_file="$filepath.tmp"
    local backup_file="$filepath.bak"
    local download_success=0

    for url in "${urls[@]}"; do
        echo "Updating $filename from $url..."
        
        if wget -q -O "$temp_file" "$url"; then
            if [ -s "$temp_file" ]; then
                download_success=1
                break
            else
                echo "Downloaded $filename from $url is empty, trying next..."
                rm -f "$temp_file"
            fi
        else
            echo "Failed to download $filename from $url, trying next..."
            rm -f "$temp_file"
        fi
    done

    if [ "$download_success" -ne 1 ]; then
        echo "All download attempts failed for $filename, keeping existing file"
        return 1
    fi

    if [ -f "$filepath" ]; then
        cp "$filepath" "$backup_file"
    fi

    mv "$temp_file" "$filepath"
    echo "Successfully updated $filename"
    update_success=1
    return 0
}

update_file "gfwlist.txt" \
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt" \
    "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt" || true

update_file "china_ip.txt" \
    "https://china-operator-ip.yfgao.com/china46.txt" || true

update_file "china_domain.txt" \
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/china-list.txt" \
    "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/china-list.txt" || true

echo "List update completed"

if [ "$update_success" -eq 1 ]; then
    echo "Restarting smartdns..."
    if [ -d "/etc/service/smartdns" ] || [ -d "/etc/runit/smartdns" ]; then
        sv restart smartdns 2>/dev/null || true
    fi
fi
