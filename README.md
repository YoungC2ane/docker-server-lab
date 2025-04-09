# **项目目标**

1. 提供可复现的Docker化服务器环境，用于：
   - 防火墙（iptables/firewalld）规则实验
   - 模拟服务器软件漏洞（如旧版Apache/Nginx）及修补测试
   - 网络隔离策略验证
2. 成为学习Linux系统管理和网络安全的实践沙盒

# 项目结构

```
docker-server-lab/
│
├── docs/                     # 项目文档目录
│   ├── firewall-guide.md     # 防火墙配置指南（规则说明、实验步骤）
│   └── vulnerability-demo.md # 漏洞复现演示文档（CVE案例说明）
│
├── environments/             # 所有实验环境配置
│   ├── cve-xxxx-xxxx/        # CVE漏洞复现环境（示例目录，需替换具体CVE编号）
│   └── firewall/            # 防火墙实验环境
│       ├── docker-compose.yml  # 定义3个容器的编排文件（如Web服务、客户端）
│       └── Dockerfile          # 构建带httpd的CentOS镜像（用于模拟Web服务）
│
├── scripts/                  # 运维脚本目录
│   ├── linux/                # Linux专用脚本
│   │   ├── cleanup.sh        # 清理实验残留资源（清理容器、镜像、网络）
│   │   └── init-env.sh       # 环境初始化脚本（配置容器、镜像、网络）
│   └── win/                  # Windows专用脚本
│       ├── cleanup.ps1       # 清理PowerShell脚本（清理容器、镜像、网络）
│       └── init-env.ps1      # Windows环境初始化（配置容器、镜像、网络）
│
└── (其他目录，如samples/test等，可根据需要后续补充)
```





