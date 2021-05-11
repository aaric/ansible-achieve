#/bin/sh
# 1. init yum.repo
sudo cp -a /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
sudo curl -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo
sudo curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
sudo yum clean all
sudo yum repolist all

# 2. disable selinux
sudo sed -i --follow-symlinks "s/^SELINUX=enforcing/SELINUX=disabled/g" \
  /etc/selinux/config
sudo setenforce 0

# 3. disable firewalld & postfix
sudo systemctl disable firewalld --now
sudo systemctl disable postfix --now

# 4. set timezone +08:00
sudo timedatectl set-timezone Asia/Shanghai

# 5. install ansible
if [ "$HOSTNAME" = "k8s-master" ] ; then
  sudo yum install -y ansible
fi
