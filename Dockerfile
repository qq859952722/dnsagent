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

RUN ADGUARD_VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | jq -r '.tag_name') && \
    wget -O adguardhome.tar.gz "https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADGUARD_VERSION}/AdGuardHome_linux_amd64.tar.gz" && \
    tar -xzf adguardhome.tar.gz && \
    mv AdGuardHome/AdGuardHome /usr/local/bin/ && \
    rm -rf adguardhome.tar.gz AdGuardHome && \
    \
    SMARTDNS_VERSION=$(curl -s https://api.github.com/repos/pymumu/smartdns/releases/latest | jq -r '.tag_name') && \
    wget -O smartdns.tar.gz "https://github.com/pymumu/smartdns/releases/download/${SMARTDNS_VERSION}/smartdns-x86_64-linux-all.tar.gz" && \
    tar -xzf smartdns.tar.gz && \
    mv smartdns/usr/sbin/smartdns /usr/local/bin/ && \
    rm -rf smartdns.tar.gz smartdns && \
    \
    DNSCRYPT_PROXY_VERSION=$(curl -s https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest | jq -r '.tag_name') && \
    DNSCRYPT_VERSION_NUM=${DNSCRYPT_PROXY_VERSION#v} && \
    wget -O dnscrypt-proxy.tar.gz "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${DNSCRYPT_PROXY_VERSION}/dnscrypt-proxy-linux_x86_64-${DNSCRYPT_VERSION_NUM}.tar.gz" && \
    tar -xzf dnscrypt-proxy.tar.gz && \
    mv linux-x86_64/dnscrypt-proxy /usr/local/bin/ && \
    rm -rf dnscrypt-proxy.tar.gz linux-x86_64

COPY rootfs/ /

RUN chmod +x /usr/local/bin/*.sh \
    && chmod +x /etc/runit/*/run \
    && mkdir -p /config

WORKDIR /back/smartdns/list
RUN wget -O gfwlist.txt "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt" || true && \
    wget -O china_ip.txt "https://china-operator-ip.yfgao.com/china46.txt" || true && \
    wget -O china_domain.txt "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/china-list.txt" || true

EXPOSE 53/tcp 53/udp 3000/tcp 80/tcp

VOLUME ["/config"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
