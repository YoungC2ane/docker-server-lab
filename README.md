# **项目目标**

1. 提供可复现的Docker化服务器环境，用于：
   - 防火墙（iptables/firewalld）规则实验
   - 模拟服务器软件漏洞（如旧版Apache/Nginx）及修补测试
   - 网络隔离策略验证
2. 成为学习Linux系统管理和网络安全的实践沙盒

# 项目结构

```
docker-server-lab/
├── environments/             # 所有实验环境配置
│   └── firewall/             # 防火墙实验环境
│       ├── docker-compose.yml  # 定义3个容器的编排文件
│       └── Dockerfile          # 构建带httpd的CentOS镜像
│
├── scripts/                  # 运维脚本目录
│   ├── linux/                # Linux/macOS专用脚本
│   │   └── init-env.sh       # 环境初始化脚本（Bash）
│   └── win/                  # Windows专用脚本
│       └── init-env.ps1      # 环境初始化脚本（PowerShell）
│
└── (其他目录，如docs/samples等，可根据需要后续补充)
```





