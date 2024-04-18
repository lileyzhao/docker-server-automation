#!/bin/bash

# --------------------------------------------------------------------------------
# 脚本名称: install_docker_tools.sh
# 版本: 1.0
# 创建日期: 2024-04-19
# 作者: [您的名字或昵称]
# 联系方式: [您的邮箱或其他联系方式]
# 描述: 本脚本用于一键安装Docker及相关管理工具，包括Portainer-CE汉化版、NginxWebUI和Watchtower。
# 使用说明: 以root用户或使用sudo权限运行此脚本。在执行前，请确保目标系统为CentOS或兼容系统。
# 版权信息: © [年份] [您的名字或公司名]. 保留所有权利。
# 免责声明: 本脚本提供“按原样”使用，不提供任何明示或暗示的保证。使用者自行承担使用风险。
# --------------------------------------------------------------------------------

# 停止脚本在遇到错误时继续执行
set -e

# 1. 移除docker安装残留
echo "移除Docker安装残留..."
yum remove -y docker \
           docker-client \
           docker-client-latest \
           docker-common \
           docker-latest \
           docker-latest-logrotate \
           docker-logrotate \
           docker-engine

# 2. 安装必要程序
echo "安装必要程序..."
yum install -y yum-utils \
               device-mapper-persistent-data \
               lvm2

# 3. 添加阿里云Docker-CE源
echo "添加阿里云Docker-CE源..."
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 4. 开始安装最新版Docker-CE
echo "安装最新版Docker-CE..."
yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 5. 启动Docker
echo "启动Docker..."
systemctl start docker

# 6. 安装Docker Web管理工具 Portainer-CE汉化版
echo "安装Portainer-CE汉化版..."
docker volume create portainer_data
docker run -d -p 25710:9443 -p 25711:9000 -p 25712:8000 \
           --name portainer \
           --restart=always \
           -v /var/run/docker.sock:/var/run/docker.sock \
           -v portainer_data:/data \
           6053537/portainer-ce

# 7. 安装 Nginx Web管理工具 NginxWebUI最新版
echo "安装NginxWebUI最新版..."
docker volume create nginxwebui_data
docker run -itd \
           --name nginxui \
           --restart=always \
           -v nginxwebui_data:/home/nginxWebUI \
           -e BOOT_OPTIONS="--server.port=25713" \
           --privileged=true \
           --net=host \
           cym1102/nginxwebui

# 8. 安装Watchtower容器自动更新工具
echo "最后一步，安装Watchtower容器自动更新工具..."
# 获取用户输入的私有仓库账号和密码
read -p "请输入私有仓储的账号（如不用私有git库请直接回车）: " repo_user
repo_user=${repo_user:-repousername}

read -p "请输入私有仓储的密码（如不用私有git库直接回车）: " repo_pass
repo_pass=${repo_pass:-repopassword}

# 获取用户输入的检查更新间隔
read -p "请输入检查容器更新的间隔（秒），直接回车默认为30秒: " interval
interval=${interval:-30}

docker run -d --name watchtower \
           --restart=always \
           --volume /var/run/docker.sock:/var/run/docker.sock \
           -v /etc/localtime:/etc/localtime:ro \
           -e REPO_USER=$repo_user \
           -e REPO_PASS=$repo_pass \
           containrrr/watchtower:1.7.1 -i $interval --cleanup \
           -x watchtower,portainer,nginxui

echo "安装完成！🎉🎉🎉"
