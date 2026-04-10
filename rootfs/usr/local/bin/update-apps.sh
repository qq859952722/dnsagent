#!/bin/bash

set -e

BIN_DIR="/usr/local/bin"
TMP_DIR="/tmp/update-apps"
mkdir -p "$TMP_DIR"

confirm() {
    local prompt="$1"
    read -p "$prompt (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

restart_service() {
    local service_name="$1"
    echo "Restarting $service_name..."
    if [ -d "/etc/service/$service_name" ] || [ -d "/etc/runit/$service_name" ]; then
        sv restart "$service_name" 2>/dev/null || true
    fi
}

update_smartdns() {
    local local_version=""
    if [ -f "$BIN_DIR/smartdns" ]; then
        local_version=$($BIN_DIR/smartdns -v 2>&1 | grep -oP 'Release\d+' || true)
    fi
    echo "SmartDNS local version: ${local_version:-unknown}"

    local latest_version=$(curl -s https://api.github.com/repos/pymumu/smartdns/releases/latest | grep -oP '"tag_name": "\K[^"]+')
    echo "SmartDNS latest version: $latest_version"

    if [ "$local_version" = "$latest_version" ]; then
        echo "SmartDNS is already up to date"
        return
    fi

    if ! confirm "Update SmartDNS to $latest_version?"; then
        echo "Skipping SmartDNS update"
        return
    fi

    local download_url="https://github.com/pymumu/smartdns/releases/download/${latest_version}/smartdns-x86_64-linux-all.tar.gz"
    local temp_file="$TMP_DIR/smartdns.tar.gz"
    if ! wget -q -O "$temp_file" "$download_url"; then
        echo "Failed to download SmartDNS"
        rm -f "$temp_file"
        return
    fi

    if [ -f "$BIN_DIR/smartdns" ]; then
        cp "$BIN_DIR/smartdns" "$BIN_DIR/smartdns.bak"
    fi

    tar -xzf "$temp_file" -C "$TMP_DIR"
    mv "$TMP_DIR/smartdns/usr/sbin/smartdns" "$BIN_DIR/"
    chmod +x "$BIN_DIR/smartdns"

    rm -rf "$temp_file" "$TMP_DIR/smartdns"
    echo "SmartDNS updated successfully"
    
    restart_service smartdns
}

update_dnscrypt_proxy() {
    local local_version=""
    if [ -f "$BIN_DIR/dnscrypt-proxy" ]; then
        local_version=$($BIN_DIR/dnscrypt-proxy -version 2>&1 | grep -oP '\d+\.\d+\.\d+' || true)
    fi
    echo "dnscrypt-proxy local version: ${local_version:-unknown}"

    local latest_version=$(curl -s https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest | grep -oP '"tag_name": "\K[^"]+')
    echo "dnscrypt-proxy latest version: $latest_version"

    if [ "v$local_version" = "$latest_version" ]; then
        echo "dnscrypt-proxy is already up to date"
        return
    fi

    if ! confirm "Update dnscrypt-proxy to $latest_version?"; then
        echo "Skipping dnscrypt-proxy update"
        return
    fi

    local version_num=${latest_version#v}
    local download_url="https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${latest_version}/dnscrypt-proxy-linux_x86_64-${version_num}.tar.gz"
    local temp_file="$TMP_DIR/dnscrypt-proxy.tar.gz"
    if ! wget -q -O "$temp_file" "$download_url"; then
        echo "Failed to download dnscrypt-proxy"
        rm -f "$temp_file"
        return
    fi

    if [ -f "$BIN_DIR/dnscrypt-proxy" ]; then
        cp "$BIN_DIR/dnscrypt-proxy" "$BIN_DIR/dnscrypt-proxy.bak"
    fi

    tar -xzf "$temp_file" -C "$TMP_DIR"
    mv "$TMP_DIR/linux-x86_64/dnscrypt-proxy" "$BIN_DIR/"
    chmod +x "$BIN_DIR/dnscrypt-proxy"
    rm -rf "$TMP_DIR/linux-x86_64"

    rm -f "$temp_file"
    echo "dnscrypt-proxy updated successfully"
    
    restart_service dnscrypt-proxy
}

echo "=== DNSAgent Application Updater ==="
echo

update_smartdns
echo
update_dnscrypt_proxy
echo

rm -rf "$TMP_DIR"
echo "Update process completed"
