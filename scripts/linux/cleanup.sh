#!/bin/bash

# 清理脚本：删除所有相关容器、镜像和网络
set -eo pipefail

# 定义颜色常量
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 进入环境目录
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../environments/firewall" && pwd)"
cd "$ENV_DIR" || exit 1

# ---------- 清理容器 ----------
echo -e "${CYAN}[1/3] 清理容器...${NC}"

# 停止并删除 docker-compose 管理的容器
if [ -f docker-compose.yml ]; then
    docker-compose down --rmi all --remove-orphans
fi

# 强制删除残留容器
CONTAINERS=$(docker ps -a --filter "name=web1,web2,web3" -q)
if [ -n "$CONTAINERS" ]; then
    docker rm -f $CONTAINERS >/dev/null
    echo -e "${GREEN}已删除实验容器${NC}"
fi

# ---------- 清理镜像 ----------
echo -e "${CYAN}[2/3] 清理镜像...${NC}"

# 删除项目构建的镜像
IMAGES=("centos-httpd")
for image in "${IMAGES[@]}"; do
    IMAGE_IDS=$(docker images -q "$image")
    if [ -n "$IMAGE_IDS" ]; then
        docker rmi -f $IMAGE_IDS >/dev/null
        echo -e "${GREEN}已删除镜像: $image${NC}"
    fi
done

# ---------- 清理网络 ----------
echo -e "${CYAN}[3/3] 清理网络...${NC}"

# 删除自定义网络
NETWORK_NAME="centos-httpd-net"
if docker network inspect "$NETWORK_NAME" &>/dev/null; then
    docker network rm "$NETWORK_NAME" >/dev/null
    echo -e "${GREEN}已删除网络: $NETWORK_NAME${NC}"
fi

# ---------- 验证结果 ----------
echo -e "\n${GREEN}✅ 清理完成！剩余资源检查：${NC}"

echo -e "\n容器状态:"
docker ps -a --filter "name=web1,web2,web3"

echo -e "\n镜像状态:"
docker images --filter "reference=centos-httpd"

echo -e "\n网络状态:"
docker network ls --filter "name=centos-httpd-net"