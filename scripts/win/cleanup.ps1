# 清理脚本：删除所有相关容器、镜像和网络
# 进入环境目录
$envDir = Join-Path -Path $PSScriptRoot -ChildPath "../../environments/firewall"
Set-Location -Path $envDir

# ---------- 清理容器 ----------
Write-Host "`n[1/3] 清理容器..." -ForegroundColor Cyan

# 停止并删除 docker-compose 管理的容器
if (Test-Path docker-compose.yml) {
    docker-compose down --rmi all --remove-orphans
}

# 强制删除残留容器
$containers = docker ps -a --filter "name=web1,web2,web3" -q
if ($null -ne $containers) {
    docker rm -f $containers | Out-Null
    Write-Host "已删除实验容器" -ForegroundColor Green
}

# ---------- 清理镜像 ----------
Write-Host "`n[2/3] 清理镜像..." -ForegroundColor Cyan

# 删除项目构建的镜像
$images = @("centos-httpd")
foreach ($image in $images) {
    if (docker images -q $image) {
        docker rmi -f $(docker images -q $image) 2>$null
        Write-Host "已删除镜像: $image" -ForegroundColor Green
    }
}

# ---------- 清理网络 ----------
Write-Host "`n[3/3] 清理网络..." -ForegroundColor Cyan

# 删除自定义网络
$networkName = "centos-httpd-net"
if (docker network ls -q --filter name=$networkName) {
    docker network rm $networkName 2>$null
    Write-Host "已删除网络: $networkName" -ForegroundColor Green
}

# 最终状态验证
Write-Host "`n✅ 清理完成！剩余资源：" -ForegroundColor Green
docker ps -a --filter "name=web1,web2,web3"
docker images --filter "reference=centos-httpd"
docker network ls --filter "name=centos-httpd-net"