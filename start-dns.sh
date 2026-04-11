#!/bin/bash

################################################################################
# DNS Agent - 便捷启动脚本
# 
# 此脚本自动化创建 IPv6 网络和启动容器的过程
# 使用方法: chmod +x start-dns.sh && ./start-dns.sh
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# 配置变量
NETWORK_NAME="ibridge"
IPV4_SUBNET="172.20.0.0/16"
IPV6_SUBNET="fd00::/64"
CONTAINER_NAME="dnsagent"

# 函数：打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${NC}$1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# 函数：检查 Docker
check_docker() {
    print_info "检查 Docker..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装。请先安装 Docker。"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker 守护进程未运行。请启动 Docker。"
        exit 1
    fi
    
    print_success "Docker 已安装并运行"
}

# 函数：检查 Docker Compose
check_compose() {
    print_info "检查 Docker Compose..."
    
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose 未安装。请先安装 Docker Compose。"
        exit 1
    fi
    
    print_success "Docker Compose 已安装"
}

# 函数：创建网络
create_network() {
    print_info "检查 IPv6 网络..."
    
    if docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
        print_success "网络 '$NETWORK_NAME' 已存在"
        
        # 显示网络详情
        print_info "网络配置："
        docker network inspect "$NETWORK_NAME" | grep -A 5 '"IPAM"' | head -10
    else
        print_warning "网络 '$NETWORK_NAME' 不存在，正在创建..."
        
        if docker network create \
            --driver bridge \
            --subnet "$IPV4_SUBNET" \
            --ipv6 \
            --subnet "$IPV6_SUBNET" \
            "$NETWORK_NAME" 2>&1 | tail -1; then
            
            print_success "网络已创建"
            
            print_info "网络配置："
            echo "  IPv4 子网: $IPV4_SUBNET"
            echo "  IPv6 子网: $IPV6_SUBNET"
            echo "  网络名称: $NETWORK_NAME"
        else
            print_error "创建网络失败"
            exit 1
        fi
    fi
}

# 函数：启动容器
start_containers() {
    print_info "启动容器..."
    
    if docker compose up -d 2>&1; then
        print_success "容器已启动"
    else
        print_error "启动容器失败"
        exit 1
    fi
}

# 函数：等待服务就绪
wait_for_services() {
    print_info "等待服务就绪..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker compose exec -T "$CONTAINER_NAME" nslookup example.com 127.0.0.1 &> /dev/null; then
            print_success "DNS 服务已就绪"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -ne "\r检查中... ($attempt/$max_attempts)"
        sleep 1
    done
    
    echo ""
    print_warning "服务可能未完全启动，请稍待片刻"
    return 1
}

# 函数：显示服务信息
show_services() {
    print_info "容器状态："
    docker compose ps
    
    echo ""
    print_info "访问方式："
    echo ""
    echo "  🌐 Web UI (AdGuardHome):"
    echo "    • http://127.0.0.1:80"
    echo "    • http://localhost:80"
    echo ""
    echo "  🔍 DNS 服务:"
    echo "    • IPv4: 127.0.0.1:53"
    echo "    • IPv6: ::1:53"
    echo ""
    echo "  📊 SmartDNS:"
    echo "    • TCP: 127.0.0.1:5353"
    echo "    • UDP: 127.0.0.1:5353"
    echo ""
    echo "  🔐 DNSCrypt:"
    echo "    • TCP: 127.0.0.1:5054"
    echo "    • UDP: 127.0.0.1:5054"
    echo ""
    
    print_info "有用的命令:"
    echo ""
    echo "  查看日志:"
    echo "    docker compose logs -f dnsagent"
    echo ""
    echo "  进入容器:"
    echo "    docker compose exec dnsagent /bin/bash"
    echo ""
    echo "  停止容器:"
    echo "    docker compose down"
    echo ""
    echo "  重启容器:"
    echo "    docker compose restart"
    echo ""
    echo "  删除网络 (清理):"
    echo "    docker network rm $NETWORK_NAME"
    echo ""
}

# 函数：显示诊断信息
show_diagnostics() {
    echo ""
    print_info "诊断信息:"
    
    echo ""
    echo "Docker 版本:"
    docker --version
    
    echo ""
    echo "Docker Compose 版本:"
    docker compose --version
    
    echo ""
    echo "网络 '$NETWORK_NAME' 详情:"
    docker network inspect "$NETWORK_NAME" | grep -E '"Name"|"Driver"|"Subnet"' | head -10
}

# 函数：错误处理
cleanup_on_exit() {
    if [ $? -ne 0 ]; then
        echo ""
        print_error "启动过程出错，请检查上面的错误信息"
        
        echo ""
        print_info "故障排查步骤:"
        echo "  1. 检查 Docker 是否运行: docker ps"
        echo "  2. 查看错误日志: docker compose logs"
        echo "  3. 检查网络: docker network ls"
        echo "  4. 尝试手动创建网络: docker network create --driver bridge --subnet 172.20.0.0/16 --ipv6 --subnet fd00::/64 ibridge"
        echo ""
    fi
}

trap cleanup_on_exit EXIT

# 主程序流程
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   DNS Agent - 启动脚本                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # 执行检查和启动步骤
    check_docker
    echo ""
    
    check_compose
    echo ""
    
    create_network
    echo ""
    
    start_containers
    echo ""
    
    if wait_for_services; then
        echo ""
    fi
    
    show_services
    
    show_diagnostics
    
    echo ""
    print_success "DNS Agent 启动完成！"
    echo ""
}

# 执行主程序
main
