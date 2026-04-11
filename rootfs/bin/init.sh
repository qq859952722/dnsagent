#!/bin/bash
set -euo pipefail

download_with_fallback() {
    local file="$1"
    local url1="$2"
    local url2="$3"
    local temp_file="${file}.tmp"

    echo "Downloading $file..."
    if curl -fsSL -o "$temp_file" "$url1" && [ -s "$temp_file" ]; then
        echo "Successfully downloaded $file from primary URL"
        mv "$temp_file" "$file"
        return 0
    else
        echo "Primary URL failed, trying fallback..."
        if curl -fsSL -o "$temp_file" "$url2" && [ -s "$temp_file" ]; then
            echo "Successfully downloaded $file from fallback URL"
            mv "$temp_file" "$file"
            return 0
        else
            echo "Failed to download $file from both URLs"
            rm -f "$temp_file"
            return 1
        fi
    fi
}

download_binaries() {
    local BIN_DIR="${1:-$(cd "$(dirname "$0")" && pwd)}"
    local ARCH="amd64"

    mkdir -p "$BIN_DIR"

    echo "Starting download of binaries to $BIN_DIR..."

    # AdGuardHome - download latest
    local AGH_LATEST
    AGH_LATEST=$(curl -fsSL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | grep -oP '"tag_name": "\K[^"]+')
    if [ -z "$AGH_LATEST" ]; then
        echo "Failed to determine latest AdGuardHome version"
        return 1
    fi
    local AGH_URL="https://github.com/AdguardTeam/AdGuardHome/releases/download/${AGH_LATEST}/AdGuardHome_linux_${ARCH}.tar.gz"
    echo "Downloading AdGuardHome ${AGH_LATEST}..."
    curl -fsSL -o "$BIN_DIR/AdGuardHome.tar.gz" "$AGH_URL"
    tar -xzf "$BIN_DIR/AdGuardHome.tar.gz" -C "$BIN_DIR" --strip-components=1
    mv $BIN_DIR/AdGuardHome/AdGuardHome $BIN_DIR/AdGuardHome_tmp
    rm -rf $BIN_DIR/AdGuardHome
    mv $BIN_DIR/AdGuardHome_tmp $BIN_DIR/AdGuardHome
    rm -f "$BIN_DIR/AdGuardHome.tar.gz"

    # SmartDNS - download latest binary directly
    local SMARTDNS_LATEST
    SMARTDNS_LATEST=$(curl -fsSL https://api.github.com/repos/pymumu/smartdns/releases/latest | grep -oP '"tag_name": "\K[^"]+')
    if [ -z "$SMARTDNS_LATEST" ]; then
        echo "Failed to determine latest SmartDNS version"
        return 1
    fi
    local SMARTDNS_URL="https://github.com/pymumu/smartdns/releases/download/${SMARTDNS_LATEST}/smartdns-x86_64"
    echo "Downloading SmartDNS ${SMARTDNS_LATEST}..."
    curl -fsSL -o "$BIN_DIR/smartdns.bin" "$SMARTDNS_URL"

    # dnscrypt-proxy - download latest
    local DNSCRYPT_LATEST
    DNSCRYPT_LATEST=$(curl -fsSL https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest | grep -oP '"tag_name": "\K[^"]+')
    if [ -z "$DNSCRYPT_LATEST" ]; then
        echo "Failed to determine latest dnscrypt-proxy version"
        return 1
    fi
    local DNSCRYPT_ARCH="x86_64"
    local DNSCRYPT_URL="https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${DNSCRYPT_LATEST}/dnscrypt-proxy-linux_${DNSCRYPT_ARCH}-${DNSCRYPT_LATEST}.tar.gz"
    echo "Downloading dnscrypt-proxy ${DNSCRYPT_LATEST}..."
    curl -fsSL -o "$BIN_DIR/dnscrypt-proxy.tar.gz" "$DNSCRYPT_URL"
    tar -xzf "$BIN_DIR/dnscrypt-proxy.tar.gz" -C "$BIN_DIR"
    [ -f "$BIN_DIR/linux-${DNSCRYPT_ARCH}/dnscrypt-proxy" ] && mv "$BIN_DIR/linux-${DNSCRYPT_ARCH}/dnscrypt-proxy" "$BIN_DIR/"
    rm -rf "$BIN_DIR/linux-${DNSCRYPT_ARCH}" "$BIN_DIR/dnscrypt-proxy.tar.gz"

    chmod +x "$BIN_DIR/AdGuardHome" "$BIN_DIR/smartdns.bin" "$BIN_DIR/dnscrypt-proxy"
    
    # 删除不必要的文件以减少镜像大小
    rm -f "$BIN_DIR/AdGuardHome.yaml" "$BIN_DIR/README.md" "$BIN_DIR/*.md" 2>/dev/null || true
    
    # 清理掉调试符号（如果可能）以进一步减少大小
    # strip 命令会减少二进制文件的大小（移除调试符号）
    strip "$BIN_DIR/AdGuardHome" 2>/dev/null || true
    strip "$BIN_DIR/smartdns.bin" 2>/dev/null || true
    strip "$BIN_DIR/dnscrypt-proxy" 2>/dev/null || true

    echo "Download completed!"
    ls -lh "$BIN_DIR"
}

download_rule_lists() {
    local RULE_DIR="${1:-/config/smartdns/list}"
    local temp_dir="${RULE_DIR}/temp"
    local all_success=1

    mkdir -p "$RULE_DIR"
    mkdir -p "$temp_dir"

    echo "Starting download of rule lists to $RULE_DIR..."

    # 直连域名列表（大陆域名）
    local DIRECT_LIST_URL1="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
    local DIRECT_LIST_URL2="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt"
    if download_with_fallback "$temp_dir/direct-list.txt" "$DIRECT_LIST_URL1" "$DIRECT_LIST_URL2"; then
        echo "Direct list download successful"
    else
        echo "Direct list download failed"
        all_success=0
    fi

    # 代理域名列表（gfwlist）
    local PROXY_LIST_URL1="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt"
    local PROXY_LIST_URL2="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt"
    if download_with_fallback "$temp_dir/proxy-list.txt" "$PROXY_LIST_URL1" "$PROXY_LIST_URL2"; then
        echo "Proxy list download successful"
    else
        echo "Proxy list download failed"
        all_success=0
    fi

    # 中国大陆IP列表
    echo "Downloading China IP list..."
    local CHINA_IP_TEMP="$temp_dir/china46.txt"
    if curl -fsSL -o "$CHINA_IP_TEMP" "https://china-operator-ip.yfgao.com/china46.txt" && [ -s "$CHINA_IP_TEMP" ]; then
        echo "China IP list download successful"
    else
        echo "China IP list download failed"
        all_success=0
    fi

    # 只有所有文件都下载成功后才替换原文件
    if [ "$all_success" -eq 1 ]; then
        echo "All rule lists downloaded successfully, replacing original files..."
        mv "$temp_dir/direct-list.txt" "$RULE_DIR/"
        mv "$temp_dir/proxy-list.txt" "$RULE_DIR/"
        mv "$temp_dir/china46.txt" "$RULE_DIR/"
        echo "Rule list download completed!"
        ls -lh "$RULE_DIR"
    else
        echo "Some rule lists failed to download, keeping original files"
    fi

    # 清理临时目录（确保彻底清理）
    rm -rf "$temp_dir"
    return 0
}

initialize_system() {
    echo "Initializing Debian system..."

    # 更新包列表
    echo "Updating package lists..."
    apt-get update -y

    # 安装必要的依赖包（使用--no-install-recommends减少镜像大小）
    echo "Installing dependencies..."
    apt-get install -y --no-install-recommends ca-certificates curl wget tar gzip cron runit 

    # 确保目录结构存在
    echo "Creating directory structure..."
    mkdir -p /etc/adguardhome
    mkdir -p /etc/smartdns
    mkdir -p /etc/dnscrypt-proxy
    mkdir -p /config
    mkdir -p /config/smartdns/list
    mkdir -p /config_back/adguardhome
    mkdir -p /config_back/dnscrypt-proxy
    mkdir -p /var/log
    mkdir -p /var/cache
    mkdir -p /bin

    # 确保服务目录存在
    mkdir -p /etc/service/adguarddns
    mkdir -p /etc/service/smartdns
    mkdir -p /etc/service/dnscrypt-proxy
    mkdir -p /etc/service/cron

    # 下载二进制文件到/bin目录
    echo "Downloading binaries to /bin directory..."
    download_binaries "/bin"
    download_rule_lists "/config_back/smartdns/list"
    chmod +x /bin/AdGuardHome /bin/cron_tasks.sh /bin/cron_service_check.sh /etc/service/adguarddns/run /etc/service/cron/run /etc/service/dnscrypt-proxy/run /etc/service/smartdns/run || true
    
    # 清理apt缓存以减少镜像大小
    echo "Cleaning package cache..."
    apt-get clean
    apt-get autoclean
    rm -rf /var/lib/apt/lists/*
    
    echo "System initialization completed!"
}

start_services() {
    local CONFIG_DIR="/config"
    local CONFIG_BACK_DIR="/config_back"
    local RULE_LIST_DIR="/config/smartdns/list"

    echo "Starting services..."

    # 检查并复制配置文件夹
    echo "Checking configuration directories..."
    mkdir -p "$CONFIG_DIR"

    # 检查AdGuardHome配置文件夹
    if [ ! -d "$CONFIG_DIR/adguardhome" ]; then
        echo "AdGuardHome config directory not found, copying from config_back..."
        if [ -d "$CONFIG_BACK_DIR/adguardhome" ]; then
            cp -r "$CONFIG_BACK_DIR/adguardhome" "$CONFIG_DIR/"
            echo "AdGuardHome config directory copied successfully"
        else
            echo "Warning: AdGuardHome config directory not found in config_back"
        fi
    fi

    # 检查SmartDNS配置文件夹
    if [ ! -d "$CONFIG_DIR/smartdns" ]; then
        echo "SmartDNS config directory not found, copying from config_back..."
        if [ -d "$CONFIG_BACK_DIR/smartdns" ]; then
            cp -r "$CONFIG_BACK_DIR/smartdns" "$CONFIG_DIR/"
            echo "SmartDNS config directory copied successfully"
        else
            echo "Warning: SmartDNS config directory not found in config_back"
        fi
    fi

    # 检查dnscrypt-proxy配置文件夹
    if [ ! -d "$CONFIG_DIR/dnscrypt-proxy" ]; then
        echo "dnscrypt-proxy config directory not found, copying from config_back..."
        if [ -d "$CONFIG_BACK_DIR/dnscrypt-proxy" ]; then
            cp -r "$CONFIG_BACK_DIR/dnscrypt-proxy" "$CONFIG_DIR/"
            echo "dnscrypt-proxy config directory copied successfully"
        else
            echo "Warning: dnscrypt-proxy config directory not found in config_back"
        fi
    fi

    # 检查rules配置文件夹
    if [ ! -d "$CONFIG_DIR/rules" ]; then
        echo "Rules config directory not found, creating..."
        mkdir -p "$CONFIG_DIR/rules"
        echo "Rules config directory created"
    fi

    if [ -d "$RULE_LIST_DIR" ] && [ -n "$(ls -A "$RULE_LIST_DIR" 2>/dev/null)" ]; then
        echo "Copying default rule list files from $RULE_LIST_DIR to $CONFIG_DIR/rules..."
        cp -r "$RULE_LIST_DIR/." "$CONFIG_DIR/rules/" 2>/dev/null || true
    fi

    # 启动runit服务
    echo "Starting runit services in foreground..."
    exec runsvdir /etc/service
}

# 主函数，处理命令行参数
main() {
    case "$1" in
        initialize_system)
            initialize_system
            ;;
        start_services)
            start_services
            ;;
        download_rule_lists)
            shift
            download_rule_lists "$@"
            ;;
        *)
            echo "Usage: $0 {initialize_system|start_services|download_rule_lists}"
            exit 1
            ;;
    esac
}

# 如果直接运行脚本，则执行主函数
if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi




