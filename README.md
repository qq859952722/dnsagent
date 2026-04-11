# DNS Agent

基于 Docker 的全功能 DNS 解决方案容器，集成多个 DNS 组件，提供安全、快速和稳定的 DNS 服务。

## 📋 项目特性

- **AdGuardHome**：广告拦截、DNS 过滤和家长控制
- **SmartDNS**：智能 DNS 解析，支持多上游服务器和速度检测
- **DNSCrypt Proxy**：加密 DNS 通信，提供隐私保护
- **Runit 服务管理**：进程管理和自动重启机制
- **Cron 任务**：定时更新规则列表
- **IPv6 支持**：完整的 IPv6 网络支持
- **镜像优化**：443MB → 143MB，压缩比 40.2%

## 🚀 快速开始（Docker Compose）
用户名：admin
密码：adminadmin
### 方式 1: 使用默认网络（推荐用于测试）

```bash
# 直接运行
docker compose up -d

# 查看日志
docker compose logs -f dnsagent

# 停止
docker compose down
```

### 方式 2: 使用自定义 IPv6 网络（生产环境推荐）

#### 步骤 1: 创建支持 IPv6 的桥接网络

```bash
# 创建具有 IPv6 支持的自定义桥接网络
docker network create \
  --driver bridge \
  --subnet 172.20.0.0/16 \
  --ipv6 \
  --subnet fd00::/64 \
  ibridge

# 验证网络创建
docker network inspect ibridge
```

#### 步骤 2: 启动容器

```bash
# 使用 docker-compose.yml 启动（已配置 ibridge）
docker compose -f docker-compose.yml up -d

# 查看容器状态
docker compose ps

# 查看容器 IP 地址
docker compose exec dnsagent cat /etc/hosts
```

#### 步骤 3: 验证服务

```bash
# 测试 DNS 解析（IPv4）
nslookup example.com 127.0.0.1

# 测试 DNS 解析（IPv6）
nslookup example.com ::1

# 查看服务状态
docker compose logs dnsagent
```

## 📦 完整的 Docker Compose 部署

```yaml
version: '3.8'

services:
  dnsagent:
    image: ghcr.io/qq859952722/dnsagent:latest
    container_name: dnsagent
    
    # 使用自定义 IPv6 网络
    networks:
      ibridge:
        ipv4_address: 172.20.0.2
        ipv6_address: fd00::2
    
    ports:
      # DNS 服务
      - "53:53/tcp"
      - "53:53/udp"
      - "[::1]:53:53/tcp"          # IPv6 DNS TCP
      - "[::1]:53:53/udp"          # IPv6 DNS UDP
      
      # Web UI 端口（AdGuardHome）
      - "80:80/tcp"
      - "[::1]:80:80/tcp"          # IPv6 Web UI
      
      # 其他服务端口
      - "443:443/tcp"
      - "5053:5053/tcp"            # SmartDNS
    
    volumes:
      # 配置文件持久化
      - dns-config:/config
      
      # 日志目录
      - dns-logs:/var/log
    
    # 环境变量
    environment:
      TZ: Asia/Shanghai
    
    # 容器策略
    restart: always
    privileged: false
    
    # 资源限制
    # 根据实际需求调整
    # mem_limit: 512m
    # cpus: '1.0'

volumes:
  dns-config:
    driver: local
  dns-logs:
    driver: local

networks:
  ibridge:
    external: true
    driver: bridge
```

## 🔧 配置指南

### 创建 IPv6 网络的详细步骤

#### 1. 检查 Docker IPv6 支持

```bash
# 查看 Docker 当前配置
docker info | grep -i ipv6

# 如未启用，编辑 /etc/docker/daemon.json
sudo nano /etc/docker/daemon.json
```

#### 2. 配置 Docker 支持 IPv6（可选）

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "fd00::/64",
  "ip6tables": true
}
```

重启 Docker：
```bash
sudo systemctl restart docker
```

#### 3. 创建网络命令说明

```bash
# 完整命令分解
docker network create           # 创建网络
  --driver bridge               # 使用桥接驱动
  --subnet 172.20.0.0/16        # IPv4 子网
  --ipv6                        # 启用 IPv6
  --subnet fd00::/64            # IPv6 子网
  ibridge                       # 网络名称

# 中国用户可使用 CNI（可选）
# --opt com.docker.network.bridge.name=ibridge
```

#### 4. 删除网络

```bash
# 停止使用该网络的所有容器
docker compose down

# 删除网络
docker network rm ibridge
```

### 启动脚本示例

创建 `start-dns.sh`：

```bash
#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[1/3] 检查 IPv6 网络...${NC}"
if docker network inspect ibridge > /dev/null 2>&1; then
    echo -e "${GREEN}✓ ibridge 网络已存在${NC}"
else
    echo -e "${YELLOW}创建 ibridge 网络...${NC}"
    docker network create \
      --driver bridge \
      --subnet 172.20.0.0/16 \
      --ipv6 \
      --subnet fd00::/64 \
      ibridge
    echo -e "${GREEN}✓ ibridge 网络已创建${NC}"
fi

echo -e "${YELLOW}[2/3] 启动容器...${NC}"
docker compose up -d
echo -e "${GREEN}✓ 容器已启动${NC}"

echo -e "${YELLOW}[3/3] 验证服务...${NC}"
sleep 3
docker compose ps
echo -e "${GREEN}✓ 部署完成！${NC}"

echo ""
echo "访问 Web UI:"
echo "  AdGuardHome: http://localhost:80"
echo ""
echo "DNS 服务地址:"
echo "  IPv4: 127.0.0.1:53"
echo "  IPv6: ::1:53"
```

使用方法：
```bash
chmod +x start-dns.sh
./start-dns.sh
```

## 📡 服务端口

| 服务 | 协议 | IPv4 | IPv6 | 说明 |
|------|------|------|------|------|
| AdGuardHome | TCP/UDP | 3000 | ::1:3000 | Web UI 和 DNS API |
| SmartDNS | TCP/UDP | 53 | ::1:53 | 智能 DNS 解析 |
| DNSCrypt | TCP/UDP | 5053 | ::1:5053 | 加密 DNS 服务 |

## 🔐 网络架构

```
┌─────────────────────────────────────────┐
│      Host Machine                       │
│  ┌─────────────────────────────────────┐│
│  │  ibridge Network (IPv4 + IPv6)      ││
│  │  172.20.0.0/16 | fd00::/64          ││
│  │                                     ││
│  │  ┌──────────────────────────────┐  ││
│  │  │  dnsagent Container          │  ││
│  │  │  172.20.0.2 | fd00::2        │  ││
│  │  │                              │  ││
│  │  │  ┌────────────────────────┐  │  ││
│  │  │  │ AdGuardHome   (80)     │  │  ││
│  │  │  │ SmartDNS      (53)     │  │  ││
│  │  │  │ DNSCrypt      (5053)   │  │  ││
│  │  │  └────────────────────────┘  │  ││
│  │  └──────────────────────────────┘  ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## 📝 持久化数据

容器使用两个 Docker Volume 保存数据：

### 1. `dns-config` 卷
存储 DNS 配置文件：
```
/config/
├── adguardhome/          # AdGuardHome 配置
├── smartdns/            # SmartDNS 配置
├── dnscrypt-proxy/      # DNSCrypt 配置
└── rules/               # DNS 规则列表
```

### 2. `dns-logs` 卷
存储日志文件：
```
/var/log/
├── AdGuardHome.log
├── smartdns.log
└── dnscrypt-proxy.log
```

### 查看数据位置

```bash
# 查看卷信息
docker volume inspect dns-config
docker volume inspect dns-logs

# 进入容器查看
docker compose exec dnsagent ls -la /config
```

## 🐳 Docker 镜像信息

### 镜像拉取

```bash
# 最新版本
docker pull ghcr.io/qq859952722/dnsagent:latest

# 特定版本
docker pull ghcr.io/qq859952722/dnsagent:v1.0.0

# main 分支版本
docker pull ghcr.io/qq859952722/dnsagent:main
```

### 镜像大小

| 版本 | 大小 | 说明 |
|------|------|------|
| 原始 | 239 MB | 优化前 |
| 优化后 | 143 MB | 40.2% 压缩 |

## 🔄 自动更新

工作流配置每周一 23:17 UTC 自动构建 `latest` 标签。

除非发布新版本标签 (如 `v1.0.0`)，否则：
- `git push origin main` 不会触发立即构建
- 代码变更会在下一周自动构建

立即部署最新代码：
```bash
# 如果有重要更新，创建新的 Release tag
git tag v1.1.0
git push origin v1.1.0

# 然后拉取新镜像
docker pull ghcr.io/qq859952722/dnsagent:v1.1.0
```

## 🛠️ 管理命令

### 查看日志

```bash
# 实时查看日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f dnsagent

# 查看最后 100 行
docker compose logs --tail=100 dnsagent
```

### 进入容器

```bash
# 进入容器 shell
docker compose exec dnsagent /bin/bash

# 查看规则列表
docker compose exec dnsagent ls -la /config/rules/

# 检查服务状态
docker compose exec dnsagent ps aux
```

### 重启容器

```bash
# 重启所有服务
docker compose restart

# 重启特定服务
docker compose restart dnsagent

# 停止并重新启动
docker compose down
docker compose up -d
```

### 更新镜像

```bash
# 拉取最新镜像
docker compose pull

# 应用最新镜像
docker compose up -d
```

## 📊 DNS 规则更新

容器会在启动时下载最新的 DNS 规则列表：

- **direct-list.txt** (1.5M)：直连域名列表
- **proxy-list.txt** (380K)：代理域名列表
- **china46.txt** (90K)：中国 IP 列表

手动更新规则：

```bash
# SSH 进入容器
docker compose exec dnsagent /bin/bash

# 运行更新命令
/bin/init.sh download_rule_lists /config/smartdns/list

# 重启 DNS 服务
docker compose restart dnsagent
```

## 🔍 故障排查

### 1. IPv6 连接无法正常工作

```bash
# 检查网络配置
docker network inspect ibridge

# 检查容器 IPv6 地址
docker compose exec dnsagent ip addr show

# 测试 IPv6 连接
docker compose exec dnsagent ping -6 ipv6.google.com
```

### 2. DNS 查询超时

```bash
# 查看容器日志
docker compose logs dnsagent

# 进入容器测试
docker compose exec dnsagent /bin/bash
nslookup example.com 127.0.0.1
```

### 3. 规则列表下载失败

```bash
# 检查网络连接
docker compose exec dnsagent curl -I https://github.com

# 手动触发下载
docker compose exec dnsagent /bin/init.sh download_rule_lists /config/smartdns/list
```

### 4. 磁盘空间不足

```bash
# 查看卷大小
docker volume inspect dns-config | grep Mountpoint
du -sh /var/lib/docker/volumes/dnsagent_dns-config/_data

# 清理未使用的卷
docker volume prune
```

## 📚 更多资源

- [AdGuardHome 文档](https://adguard.com/en/adguardhome/overview.html)
- [SmartDNS 项目](https://github.com/pymumu/smartdns)
- [DNSCrypt 项目](https://github.com/DNSCrypt/dnscrypt-proxy)
- [Docker Compose 文档](https://docs.docker.com/compose/)

## 📝 优化历史

### v1.0.0 - 镜像优化

- ✅ 镜像大小由 239 MB 压缩至 143 MB (40.2%)
- ✅ APT 包管理优化（移除推荐依赖）
- ✅ 二进制文件优化（移除调试符号）
- ✅ 临时文件清理
- ✅ 构建流程优化

详见：[优化报告](./README_OPTIMIZATION.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT License
