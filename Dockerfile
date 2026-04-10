FROM debian:bookworm-slim

LABEL maintainer="dnsagent"

RUN apt-get update && apt-get install -y \
    runit \
    curl \
    wget \
    ca-certificates \
    cron \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN set -e && \
    \
    # 下载 AdGuardHome
    ADGUARD_VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | jq -r '.tag_name') && \
    echo "Downloading AdGuardHome ${ADGUARD_VERSION}..." && \
    wget -q -O adguardhome.tar.gz "https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADGUARD_VERSION}/AdGuardHome_linux_amd64.tar.gz" && \
    tar -xzf adguardhome.tar.gz && \
    mv AdGuardHome/AdGuardHome /usr/local/bin/ && \
    rm -rf adguardhome.tar.gz AdGuardHome && \
    \
    # 下载 SmartDNS - 使用正确的资源获取方法
    SMARTDNS_VERSION=$(curl -s https://api.github.com/repos/pymumu/smartdns/releases/latest | jq -r '.tag_name') && \
    echo "Downloading SmartDNS ${SMARTDNS_VERSION}..." && \
    SMARTDNS_BINARY_URL=$(curl -s https://api.github.com/repos/pymumu/smartdns/releases/latest | jq -r '.assets[] | select(.name | contains("x86_64") and contains("linux") and (contains(".tar.gz") or contains("linux"))) | .browser_download_url' | head -n1) && \
    if [ -z "${SMARTDNS_BINARY_URL}" ]; then echo "Failed to get SmartDNS download URL"; exit 1; fi && \
    wget -q -O smartdns.tar.gz "${SMARTDNS_BINARY_URL}" && \
    if tar -tzf smartdns.tar.gz > /dev/null 2>&1; then \
        tar -xzf smartdns.tar.gz -C /tmp && \
        find /tmp -name "smartdns" -type f -exec mv {} /usr/local/bin/smartdns \; && \
        rm -rf smartdns.tar.gz /tmp/smartdns* /tmp/*/smartdns*; \
    else \
        mv smartdns.tar.gz /usr/local/bin/smartdns; \
    fi && \
    chmod +x /usr/local/bin/smartdns && \
    \
    # 下载 dnscrypt-proxy
    DNSCRYPT_PROXY_VERSION=$(curl -s https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest | jq -r '.tag_name') && \
    echo "Downloading dnscrypt-proxy ${DNSCRYPT_PROXY_VERSION}..." && \
    DNSCRYPT_VERSION_NUM=${DNSCRYPT_PROXY_VERSION#v} && \
    wget -q -O dnscrypt-proxy.tar.gz "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${DNSCRYPT_PROXY_VERSION}/dnscrypt-proxy-linux_x86_64-${DNSCRYPT_VERSION_NUM}.tar.gz" && \
    tar -xzf dnscrypt-proxy.tar.gz && \
    if [ -d "linux-x86_64" ]; then \
        mv linux-x86_64/dnscrypt-proxy /usr/local/bin/ && \
        rm -rf linux-x86_64; \
    else \
        mv dnscrypt-proxy /usr/local/bin/; \
    fi && \
    chmod +x /usr/local/bin/dnscrypt-proxy && \
    rm -rf dnscrypt-proxy.tar.gz

COPY rootfs/ /

RUN chmod +x /usr/local/bin/*.sh \
    && chmod +x /etc/runit/*/run \
    && mkdir -p /config

WORKDIR /back/smartdns/list
RUN wget -q -O gfwlist.txt "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt" 2>/dev/null || true && \
    wget -q -O china_ip.txt "https://china-operator-ip.yfgao.com/china46.txt" 2>/dev/null || true && \
    wget -q -O china_domain.txt "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/china-list.txt" 2>/dev/null || true

EXPOSE 53/tcp 53/udp 3000/tcp 80/tcp

VOLUME ["/config"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
