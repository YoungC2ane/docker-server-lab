# 进入环境目录
$envDir = Join-Path -Path $PSScriptRoot -ChildPath "../../environments/firewall"
Set-Location -Path $envDir

# ---------- 重置现有容器 ----------
Write-Host "[0/3] 清理旧容器..." -ForegroundColor Yellow
docker-compose down --remove-orphans

# ---------- 网络管理 ----------
Write-Host "[1/3] 配置网络..." -ForegroundColor Cyan

# 删除旧网络（如果存在）
if (docker network inspect centos-httpd-net -f '{{.Name}}' 2>&1) {
    Write-Host "移除旧网络: centos-httpd-net"
    docker network rm centos-httpd-net 2>$null
}

# 创建新网络
Write-Host "创建新网络: centos-httpd-net"
docker network create centos-httpd-net | Out-Null

# ---------- 启动容器 ----------
Write-Host "[2/3] 启动容器..." -ForegroundColor Cyan
docker-compose up -d --force-recreate

# ---------- 验证状态 ----------
Write-Host "[3/3] 环境状态检查：" -ForegroundColor Green

# 容器状态
docker-compose ps

# 测试容器间通信...
Write-Host "`n测试容器间通信..." -ForegroundColor Cyan
$containers = @("web1", "web2", "web3")
foreach ($container in $containers) {
    # 静默模式执行curl，不输出内容
    docker exec $container curl -s -o /dev/null http://web1 --connect-timeout 2
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$container 通信正常 ✅" -ForegroundColor Green
    } else {
        Write-Host "$container 通信失败 ❌" -ForegroundColor Red
    }
}