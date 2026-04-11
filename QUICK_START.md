# 🚀 快速开始指南

## 📋 30 秒快速启动

### 推荐方式（使用启动脚本）

```bash
# 1. 赋予脚本执行权限
chmod +x start-dns.sh

# 2. 运行启动脚本（自动完成所有步骤）
./start-dns.sh

# 完成！访问 http://localhost:80 查看 Web UI
```

### 手动启动（分步骤）

```bash
# 第 1 步：创建 IPv6 网络
docker network create \
  --driver bridge \
  --subnet 172.20.0.0/16 \
  --ipv6 \
  --subnet fd00::/64 \
  ibridge

# 第 2 步：启动容器
docker compose up -d

# 完成！
```

---

## 🔗 常用访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| **Web UI** | http://localhost:80 | AdGuardHome 管理界面 |
| **DNS (IPv4)** | 127.0.0.1:53 | DNS 查询入口 |
| **DNS (IPv6)** | ::1:53 | IPv6 DNS 查询 |
| **SmartDNS** | 127.0.0.1:5353 | 智能 DNS 解析 |
| **DNSCrypt** | 127.0.0.1:5054 | 加密 DNS 服务 |

---

## 🧪 验证服务正常

```bash
# 测试 DNS 查询
nslookup example.com 127.0.0.1
nslookup example.com ::1

# 查看容器状态
docker compose ps

# 查看实时日志
docker compose logs -f dnsagent

# 进入容器
docker compose exec dnsagent /bin/bash
```

---

## 📦 网络创建详解

### 什么是 ibridge 网络？

一个自定义的 Docker 桥接网络，支持 IPv4 和 IPv6：

```
ibridge 网络
├─ IPv4 子网: 172.20.0.0/16
│  └─ 容器 IP: 172.20.0.2
│
└─ IPv6 子网: fd00::/64
   └─ 容器 IP: fd00::2
```

### 为什么需要自定义网络？

✅ 支持 IPv6 通信
✅ 可与其他容器通信
✅ 生产环境最佳实践
✅ 便于容器编排和管理

### 创建网络的完整命令

```bash
docker network create \
  --driver bridge               # 使用桥接驱动程序
  --subnet 172.20.0.0/16        # IPv4 子网
  --ipv6                        # 启用 IPv6 支持
  --subnet fd00::/64            # IPv6 子网
  ibridge                       # 网络名称
```

### 检查网络是否创建成功

```bash
# 列出所有网络
docker network ls | grep ibridge

# 查看网络详情
docker network inspect ibridge

# 查看网络中的容器
docker network inspect ibridge | grep -A 20 "Containers"
```

---

## 🛑 停止和清理

### 停止容器

```bash
# 停止但保留容器
docker compose stop

# 停止并删除容器
docker compose down

# 停止并删除容器和卷
docker compose down -v
```

### 删除网络

```bash
# 通常自动清理，如需手动删除
docker network rm ibridge
```

### 完全清理（仅在必要时）

```bash
# 停止所有容器
docker compose down -v

# 删除网络
docker network rm ibridge

# 清理 DNS 配置卷
docker volume rm dnsagent_dns-config
docker volume rm dnsagent_dns-logs

# 移除镜像（可选）
docker rmi ghcr.io/qq859952722/dnsagent:latest
```

---

## 🆘 常见问题

### Q: "cannot connect to network driver" 错误

```bash
# 解决方案：确保 Docker 守护进程运行
sudo systemctl restart docker
docker ps  # 测试连接
```

### Q: IPv6 不工作

```bash
# 检查系统是否支持 IPv6
ip addr show

# 检查 Docker IPv6 配置
docker info | grep -i ipv6

# 如果输出为空，需要在 /etc/docker/daemon.json 中启用 IPv6
# 然后重启 Docker
```

### Q: 端口已被占用

```bash
# 查看占用的端口
sudo lsof -i :53
sudo lsof -i :80

# 解决方案：
# 1. 更改 docker-compose.yml 中的端口
# 2. 或停止占用端口的其他服务
```

### Q: 容器启动失败

```bash
# 查看详细错误日志
docker compose logs dnsagent

# 检查网络连接
docker compose exec dnsagent ping 8.8.8.8

# 验证卷挂载
docker compose exec dnsagent ls -la /config
```

### Q: DNS 查询没有响应

```bash
# 进入容器调试
docker compose exec dnsagent /bin/bash

# 测试本地 DNS
nslookup example.com 127.0.0.1

# 检查服务进程
ps aux | grep -E "AdGuard|smartdns|dnscrypt"
```

---

## 📝 管理任务

### 查看日志

```bash
# 实时日志
docker compose logs -f

# 最后 N 行
docker compose logs --tail=50

# 查看特定容器
docker compose logs dnsagent
```

### 更新镜像

```bash
# 拉取最新镜像
docker compose pull

# 重新创建容器
docker compose up -d
```

### 备份配置

```bash
# 备份配置数据
docker volume inspect dnsagent_dns-config | grep Mountpoint

# 复制卷数据
sudo cp -r /var/lib/docker/volumes/dnsagent_dns-config/_data ~/dns-config-backup
```

### 恢复配置

```bash
# 从备份恢复
sudo cp -r ~/dns-config-backup/* /var/lib/docker/volumes/dnsagent_dns-config/_data/

# 重启容器
docker compose restart
```

---

## 💡 最佳实践

### 1. 定期备份数据

```bash
# 设置定时备份
crontab -e

# 添加：每天 2 点备份
0 2 * * * sudo cp -r /var/lib/docker/volumes/dnsagent_dns-config/_data ~/dns-config-$(date +\%Y\%m\%d)
```

### 2. 监控资源使用

```bash
# 实时监控
docker stats --no-stream dnsagent

# 定期检查磁盘
df -h /var/lib/docker
```

### 3. 设置日志轮转

Docker Compose 已配置日志轮转（100MB/10文件），无需额外配置。

### 4. 定期更新

```bash
# 每周检查更新
docker compose pull
docker compose up -d
```

---

## 🔧 高级配置

### 使用外部 DNS 源

编辑 `docker-compose.yml` 中的 `environment` 部分：

```yaml
environment:
  TZ: Asia/Shanghai
  DNS_SERVERS: 8.8.8.8,8.8.4.4,1.1.1.1
```

### 调整资源限制

```yaml
# 在 docker-compose.yml 中启用
mem_limit: 512m              # 内存限制
cpus: '1.0'                  # CPU 限制
```

### 多容器部署

创建多个 DNS 实例以提高可用性：

```bash
# 创建 docker-compose.override.yml
version: '3.8'

services:
  dnsagent2:
    extends: dnsagent
    container_name: dnsagent2
    networks:
      ibridge:
        ipv4_address: 172.20.0.3
        ipv6_address: fd00::3
    ports:
      - "8053:53/tcp"
      - "8053:53/udp"
      - "8080:80/tcp"
```

---

## 📞 获取帮助

- 查看完整文档：`cat README.md`
- 查看优化报告：`cat README_OPTIMIZATION.md`
- 查看发布配置：`cat DOCKER_PUBLISH_GUIDE.md`
- 查看启动脚本代码：`cat start-dns.sh`

---

## ✅ 检查清单

- [ ] Docker 已安装
- [ ] Docker Compose 已安装
- [ ] ibridge 网络已创建
- [ ] 容器已启动
- [ ] Web UI 可访问
- [ ] DNS 查询正常
- [ ] 配置已备份

完成以上步骤后，您的 DNS 服务已准备好！🎉
