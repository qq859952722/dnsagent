# DNS 容器项目

这是一个基于 Docker 的 DNS 解决方案容器，集成了多个 DNS 组件以提供安全、快速和稳定的 DNS 服务。

## 项目特性

- **AdGuardHome**：广告拦截和DNS过滤服务
- **SmartDNS**：智能DNS解析，支持多上游服务器和速度检测
- **DNSCrypt Proxy**：加密DNS通信，提供隐私保护
- **Runit服务管理**：进程管理和自动重启
- **Cron任务**：定时更新规则列表

## 项目结构

```
dns/
├── Dockerfile                # Docker镜像构建文件
├── README.md                 # 项目说明文档
└── rootfs/                   # 根文件系统
    ├── bin/
    │   └── init.sh           # 初始化和服务管理脚本
    ├── config_back/          # 默认配置文件备份
    │   ├── adguardhome/
    │   ├── dnscrypt-proxy/
    │   └── smartdns/
    └── etc/service/          # Runit服务配置
        ├── adguarddns/
        ├── cron/
        ├── dnscrypt-proxy/
        └── smartdns/
```

## 快速开始

### 构建镜像

```bash
docker build -t dns-container .
```

### 运行容器

```bash
docker run -d \
  --name dns-container \
  -p 53:53/tcp \
  -p 53:53/udp \
  -p 80:80 \
  -v dns-config:/config \
  dns-container
```

### 端口说明

- **53 TCP/UDP**：DNS服务端口
- **80 TCP**：AdGuardHome Web管理界面

## 配置管理

首次运行时，容器会将默认配置复制到 `/config` 目录。您可以挂载该目录到宿主机进行持久化配置。

### 配置文件位置

- **AdGuardHome**：`/config/adguardhome/AdGuardHome.yaml`
- **SmartDNS**：`/config/smartdns/smartdns.conf`
- **DNSCrypt Proxy**：`/config/dnscrypt-proxy/dnscrypt-proxy.toml`
- **规则列表**：`/config/rules/`

## 使用说明

### AdGuardHome Web界面

访问 `http://容器IP:80` 可以进入AdGuardHome的Web管理界面。

默认凭据（需要在配置中修改）：
- 用户名：admin
- 密码：（需要在配置中设置）

### DNS 工作流程

1. 客户端请求 → AdGuardHome（广告过滤）→ SmartDNS（智能解析）→ DNSCrypt Proxy（加密传输）→ 上游DNS服务器
2. 支持中国域名直连、国外域名加密访问

### 定时更新

容器内置Cron任务，定期更新规则列表（包括直连域名、代理域名和中国IP列表）。

## 技术栈

- **基础镜像**：Debian Bullseye Slim
- **服务管理**：Runit
- **DNS组件**：
  - AdGuardHome
  - SmartDNS
  - DNSCrypt Proxy
- **工具**：Curl、Wget、Cron

## 故障排除

### 查看服务状态

```bash
docker exec dns-container sv status /etc/service/*
```

### 查看日志

```bash
docker logs dns-container
```

### 重启特定服务

```bash
docker exec dns-container sv restart /etc/service/adguarddns
```

## 安全建议

1. 及时修改AdGuardHome默认密码
2. 定期更新镜像以获取安全补丁
3. 根据需要配置防火墙规则限制访问
4. 使用HTTPS配置AdGuardHome管理界面

## 许可证

本项目仅供学习和研究使用。
