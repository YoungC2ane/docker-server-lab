#!/bin/bash

# 设置错误退出和显示执行命令
set -eo pipefail

# 定义颜色常量
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 进入环境目录（兼容软链接和不同调用路径）
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../environments/firewall" && pwd)"
cd "$ENV_DIR" || exit 1

# ---------- 重置现有容器 ----------
echo -e "${YELLOW}[0/3] 清理旧容器...${NC}"
docker-compose down --remove-orphans

# ---------- 网络管理 ----------
echo -e "${CYAN}[1/3] 配置网络...${NC}"

# 删除旧网络（如果存在）
if docker network inspect centos-httpd-net &>/dev/null; then
    echo -e "${CYAN}移除旧网络: centos-httpd-net${NC}"
    docker network rm centos-httpd-net >/dev/null
fi

# 创建新网络
echo -e "${CYAN}创建新网络: centos-httpd-net${NC}"
docker network create centos-httpd-net >/dev/null

# ---------- 启动容器 ----------
echo -e "${CYAN}[2/3] 启动容器...${NC}"
docker-compose up -d --force-recreate

# ---------- 验证状态 ----------
echo -e "${GREEN}[3/3] 环境状态检查：${NC}"

# 容器状态
docker-compose ps

# 测试容器间通信
echo -e "\n${CYAN}测试容器间通信...${NC}"
containers=("web1" "web2" "web3")
for container in "${containers[@]}"; do
    if docker exec "$container" curl -s -o /dev/null http://web1 --connect-timeout 2; then
        echo -e "${container} 通信正常 ${GREEN}✅${NC}"
    else
        echo -e "${container} 通信失败 ${RED}❌${NC}"
    fi
done