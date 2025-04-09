# 使用CentOS 7作为基础镜像
FROM centos:7

# 替换为阿里云镜像源
RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup \
    && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
    && yum clean all \
    && yum makecache

# 安装httpd和网络工具
RUN yum install -y httpd net-tools openssh-server nano vim iptables-services nmap-ncat ipset

# 配置SSH服务
RUN ssh-keygen -A && \ 
    echo "root:p-0p-0p-0" | chpasswd && \ 
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config  && \ 
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# 暴露80端口
EXPOSE 80 22

# 启动httpd服务（直接前台运行）
CMD ["sh", "-c", "/usr/sbin/httpd -DFOREGROUND & /usr/sbin/sshd -D"]