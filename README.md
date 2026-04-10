# DNSAgent Docker Image

一个包含 AdGuardHome、SmartDNS 和 dnscrypt-proxy 的 DNS 代理容器镜像。

## 功能特性

- **AdGuardHome**: 广告拦截和 DNS 服务器（Web 管理界面：http://localhost:3000）
- **SmartDNS**: 智能 DNS 代理，支持国内外 DNS 分流
- **dnscrypt-proxy**: DNS 加密代理，保护 DNS 查询隐私
- **runit**: 轻量级进程管理
- **自动配置初始化**: 首次启动自动复制默认配置到 /config
- **列表更新**: 支持启动时和定时更新 SmartDNS 列表
- **应用更新**: 内置工具脚本，可手动更新三个应用程序
- **CI/CD**: GitHub Actions 自动构建和推送镜像

## 快速开始

### 构建镜像

```bash
docker build -t dnsagent .
```

### 运行容器

```bash
docker run -d \
  --name dnsagent \
  -p 53:53/udp \
  -p 53:53/tcp \
  -p 3000:3000 \
  -v ./config:/config \
  dnsagent
```

### 使用环境变量

```bash
docker run -d \
  --name dnsagent \
  -p 53:53/udp \
  -p 53:53/tcp \
  -p 3000:3000 \
  -v ./config:/config \
  -e UPDATE_LISTS_ON_START=true \
  -e UPDATE_LISTS_CRON="0 4 * * *" \
  dnsagent
```

### 使用 Docker Compose

```bash
docker-compose up -d
```

**docker-compose.yml 配置说明：**
- 使用桥接网络模式
- 启用 IPv6 支持
- 包含健康检查
- 自动重启策略
- 持久化配置文件

## 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `UPDATE_LISTS_ON_START` | `false` | 启动时是否更新 SmartDNS 列表 |
| `UPDATE_LISTS_CRON` | `0 3 * * *` | 定时更新列表的 cron 表达式 |

## 目录结构

```
/config/
├── adguarddns/      # AdGuardHome 配置
├── smartdns/        # SmartDNS 配置
│   └── list/        # SmartDNS 列表文件
│       ├── gfwlist.txt
│       ├── china_ip.txt
│       └── china_domain.txt
└── dnscrypt-proxy/  # dnscrypt-proxy 配置
```

## 使用工具脚本

### 更新列表

```bash
docker exec -it dnsagent /usr/local/bin/update-lists.sh
```

### 更新应用程序

```bash
docker exec -it dnsagent /usr/local/bin/update-apps.sh
```

## 端口说明

- `53/udp`, `53/tcp`: DNS 服务
- `3000/tcp`: AdGuardHome Web 管理界面
- `80/tcp`: AdGuardHome HTTP（可选）

## 默认凭据

AdGuardHome 默认用户名：`admin`，密码：`admin`（首次登录后请立即修改）
