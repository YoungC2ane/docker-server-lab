# iptables

## **一、核心概念**

### 1. **表（Tables）**

| 表名       | 用途                                                         |
| ---------- | ------------------------------------------------------------ |
| **filter** | 默认表，用于数据包过滤（允许/拒绝流量）                      |
| **nat**    | 网络地址转换（NAT），修改源/目标 IP 和端口（如端口转发、共享上网） |
| **mangle** | 修改数据包元数据（如 TTL、QoS 标记）                         |
| **raw**    | 绕过连接跟踪（用于高性能或特殊场景）                         |

### 2. **链（Chains）**

| 链名            | 作用范围                     | 常用表         |
| --------------- | ---------------------------- | -------------- |
| **INPUT**       | 处理 **目标为本机** 的流量   | filter         |
| **OUTPUT**      | 处理 **本机发出** 的流量     | filter, mangle |
| **FORWARD**     | 处理 **经过本机转发** 的流量 | filter         |
| **PREROUTING**  | 数据包进入本机前（路由前）   | nat, raw       |
| **POSTROUTING** | 数据包离开本机前（路由后）   | nat            |

------

## **二、核心语法**

```bash
iptables -A <链名> -p <协议> --dport <目标端口> -s <源IP> -j <动作>
```

| 参数      | 说明                                                         |
| --------- | ------------------------------------------------------------ |
| `-A`      | 追加规则到链尾（`-I` 插入到链头）                            |
| `-p`      | 协议（`tcp`、`udp`、`icmp` 或 `all`）                        |
| `--dport` | 目标端口（单个端口如 `80` 或范围如 `8000:8080`）             |
| `--sport` | 源端口（通常用于限制请求来源端口）                           |
| `-s`      | 源 IP 或网段（如 `192.168.1.0/24`，省略则表示所有 IP）       |
| `-j`      | 动作：`ACCEPT`（允许）、`DROP`（静默拒绝）、`REJECT`（显式拒绝） |

------

## **三、常用命令示例** 

```bash
iptables -L -n -v  # 详细显示规则（包括流量计数）
iptables -L INPUT -n --line-numbers  # 显示INPUT链规则及行号

iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # 允许SSH
iptables -A INPUT -s 192.168.1.100 -p tcp --dport 3306 -j ACCEPT  # 允许特定IP访问MySQL
iptables -I INPUT 2 -p icmp --icmp-type echo-request -j ACCEPT  # 在第2行插入允许Ping


iptables -A INPUT -s 192.168.1.100 -p tcp --dport 3306 -j DROP #禁止单个IP访问端口
iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 22 -j DROP  # 禁止该网段访问SSH

iptables -D INPUT 3  # 删除INPUT链的第3条规则
iptables -D INPUT -p tcp --dport 22 -j ACCEPT  # 删除匹配的SSH规则
iptables -F        # 清空当前表的所有规则
iptables -F INPUT  # 仅清空INPUT链

iptables -P INPUT DROP    # 默认拒绝所有入站
iptables -P INPUT ACCEPT # 默认允许所有入站
# 手动添加拒绝所有规则（可后续删除）
iptables -A INPUT -j DROP
# 删除这条规则的方法：
iptables -D INPUT -j DROP

iptables-save > /etc/iptables.rules  # 所有表规则备份
iptables-save > /etc/sysconfig/iptables  # CentOS默认路径
```

批量导入 IP

```bash
#使用 ipset 管理 IP 列表
ipset create ALLOWED_IPS hash:ip  # 创建名为 ALLOWED_IPS 的 IP 集合
# 逐条添加（适合少量 IP）
ipset add ALLOWED_IPS 192.168.1.1
ipset add ALLOWED_IPS 10.0.0.5
# 或从文件批量导入（适合大量 IP）
echo -e "192.168.1.1\n10.0.0.5\n203.0.113.10" > ip_list.txt
while read ip; do ipset add ALLOWED_IPS "$ip"; done < ip_list.txt
# 允许集合内的 IP 访问端口
iptables -A INPUT -p tcp --dport 80 -m set --match-set ALLOWED_IPS src -j ACCEPT
# 删除规则
iptables -D INPUT -p tcp --dport 80 -m set --match-set ALLOWED_IPS src -j ACCEPT

# 查看集合内容
ipset list ALLOWED_IPS

# 删除某个 IP
ipset del ALLOWED_IPS 192.168.1.100

# 清空集合
ipset flush ALLOWED_IPS

# 删除整个集合
ipset destroy ALLOWED_IPS
```

**流量匹配逻辑**：

```bash
# 允许 SSH（规则1）
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许 HTTP（规则2）
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 默认拒绝所有其他入站（规则3）
iptables -P INPUT DROP
```

- 如果访问 **22端口**：匹配规则1 → 允许 → **跳过后续规则**。
- 如果访问 **80端口**：匹配规则2 → 允许 → **跳过后续规则**。
- 如果访问 **其他端口**：不匹配规则1和2 → 触发默认策略 `DROP`。

规则编号（`num`）越小，优先级越高

## 四、场景示例

服务器：172.19.0.2

客户端：172.19.0.3 172.19.0.4

### 增加端口入站策略

服务器 172.19.0.2：

```bash
# 默认规则允许所有连接
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination

# 开放22端口，默认拒绝其他端口
[root@10f25c59dfa0 ~]# iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # 允许SSH
[root@10f25c59dfa0 ~]# iptables -P INPUT DROP    # 默认拒绝所有入站
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22

```

客户端 172.19.0.3：

```bash
# 可访问22端口，不可访问80端口
[root@f4b9ab22f2d7 ~]# nc -zv 172.19.0.2 22
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connected to 172.19.0.2:22.
Ncat: 0 bytes sent, 0 bytes received in 0.00 seconds.
[root@f4b9ab22f2d7 ~]# nc -zv 172.19.0.2 80
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connection timed out.
```

服务器 172.19.0.2：

```bash
# 允许172.19.0.3访问80端口
[root@10f25c59dfa0 ~]iptables -A INPUT -s 172.19.0.3 -p tcp --dport 80 -j ACCEPT
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22
2    ACCEPT     tcp  --  172.19.0.3           0.0.0.0/0            tcp dpt:80

```

客户端 172.19.0.3：

```bash
# 可访问80端口和22端口
[root@f4b9ab22f2d7 ~]# nc -zv 172.19.0.2 80
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connected to 172.19.0.2:80.
Ncat: 0 bytes sent, 0 bytes received in 0.00 seconds.
[root@f4b9ab22f2d7 ~]# nc -zv 172.19.0.2 22
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connected to 172.19.0.2:22.
Ncat: 0 bytes sent, 0 bytes received in 0.00 seconds.
```

客户端 172.19.0.4：

```bash
# 不可访问80端口，可访问22端口
[root@ba4fbacef6ad ~]# nc -zv 172.19.0.2 80
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connection timed out.
[root@ba4fbacef6ad ~]# nc -zv 172.19.0.2 22
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connected to 172.19.0.2:22.
Ncat: 0 bytes sent, 0 bytes received in 0.00 seconds.
```

### 流量匹配逻辑

服务器 172.19.0.2：

```bash
# 附加丢弃80端口来自172.19.0.3的连接
[root@10f25c59dfa0 ~]# iptables -A INPUT -s 172.19.0.3 -p tcp --dport 80 -j DROP
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22
2    ACCEPT     tcp  --  172.19.0.3           0.0.0.0/0            tcp dpt:80
3    DROP       tcp  --  172.19.0.3           0.0.0.0/0            tcp dpt:80
```

客户端 172.19.0.3：

```bash
# 仍然可以访问80端口，因为规则2优先级更高
[root@f4b9ab22f2d7 ~]# nc -zv 172.19.0.2 80
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connected to 172.19.0.2:80.
Ncat: 0 bytes sent, 0 bytes received in 0.01 seconds.
```

### 删除端口入站策略

服务器 172.19.0.2：

```bash
# 删除第2条规则
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22
2    ACCEPT     tcp  --  172.19.0.3           0.0.0.0/0            tcp dpt:80
3    DROP       tcp  --  172.19.0.3           0.0.0.0/0            tcp dpt:80
[root@10f25c59dfa0 ~]# iptables -D INPUT 2
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22
2    DROP       tcp  --  172.19.0.3           0.0.0.0/0            tcp dpt:80

# 删除指定规则
[root@10f25c59dfa0 ~]# iptables -D INPUT -s 172.19.0.3 -p tcp --dport 80 -j DROP
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22
```

### 批量增加端口策略

服务器 172.19.0.2：

```bash
# 使用 ipset 管理 IP 列表
[root@10f25c59dfa0 ~]# ipset create ALLOWED_80 hash:ip

# 从文件批量导入（适合大量 IP）
[root@10f25c59dfa0 ~]# echo -e "172.19.0.3\n172.19.0.4" > ip_list_ALLOWED_80.txt
[root@10f25c59dfa0 ~]# cat ip_list_ALLOWED_80.txt
172.19.0.3
172.19.0.4
[root@10f25c59dfa0 ~]# while read ip; do ipset add ALLOWED_80 "$ip"; done < ip_list_ALLOWED_80.txt

# 查看集合内容
[root@10f25c59dfa0 ~]# ipset list ALLOWED_80
Name: ALLOWED_80
Type: hash:ip
Revision: 4
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 280
References: 0
Number of entries: 2
Members:
172.19.0.3
172.19.0.4

# 允许集合内的 IP 访问端口
[root@10f25c59dfa0 ~]# iptables -A INPUT -p tcp --dport 80 -m set --match-set ALLOWED_80 src -j ACCEPT
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22
2    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:80 match-set ALLOWED_80 src

```

客户端172.19.0.3、172.19.0.4均可访问80端口

服务器 172.19.0.2：

```bash
# 在列表中去除172.19.0.4
[root@10f25c59dfa0 ~]# ipset del ALLOWED_80 172.19.0.4
[root@10f25c59dfa0 ~]# ipset list ALLOWED_80
Name: ALLOWED_80
Type: hash:ip
Revision: 4
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 240
References: 1
Number of entries: 1
Members:
172.19.0.3

```

客户端 172.19.0.4：

```bash
# 无法访问80
[root@ba4fbacef6ad ~]# nc -zv 172.19.0.2 80
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connection timed out.
```



```bash
# 清空集合
[root@10f25c59dfa0 ~]# ipset flush ALLOWED_80
[root@10f25c59dfa0 ~]# ipset list ALLOWED_80
Name: ALLOWED_80
Type: hash:ip
Revision: 4
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 200
References: 1
Number of entries: 0
Members:
# 删除规则
[root@10f25c59dfa0 ~]# iptables -D INPUT -p tcp --dport 80 -m set --match-set ALLOWED_80 src -j ACCEPT

# 删除集合
[root@10f25c59dfa0 ~]# ipset destroy ALLOWED_80

# 查看集合
[root@10f25c59dfa0 ~]# ipset list ALLOWED_80
ipset v7.1: The set with the given name does not exist
[root@10f25c59dfa0 ~]# iptables -L INPUT -n --line-numbers
Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22

```

