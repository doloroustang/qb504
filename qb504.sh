#!/bin/bash

# 设置严格模式：任何命令失败时立即退出
set -e

# =============================================================================
# 脚本名称：qb504.sh
# 功能描述：qBittorrent 5.0.4 自动升级脚本
# 支持系统：Debian 10+ / Ubuntu 20.04+
# 运行权限：需要 root 权限
# =============================================================================
#
# 脚本功能：
# 1. 检查系统兼容性和现有 qBittorrent 安装
# 2. 自动检测用户配置和服务状态
# 3. 停止现有 qBittorrent 服务
# 4. 根据系统架构下载 qBittorrent 5.0.4 (libtorrent 1.2.20)
# 5. 直接安装到 /usr/bin/ 并设置权限
# 6. 创建 systemd 服务配置文件
# 7. 启动服务并设置开机自启
# 8. 显示服务运行状态
#
# 使用方法：chmod +x qb504.sh && ./qb504.sh
# 注意：脚本运行失败时会立即退出
# =============================================================================

# Check Root Privilege
if [ $(id -u) -ne 0 ]; then 
    echo "错误：此脚本需要root权限才能运行"
    exit 1
fi

# 查看 qBittorrent 版本
current_version=$(qbittorrent-nox --version 2>/dev/null | head -n1)
if [ $? -ne 0 ]; then
    echo "错误：无法获取 qBittorrent 版本信息"
    echo "请确保 qBittorrent 已正确安装"
    exit 1
fi

echo "当前 qBittorrent 版本：$current_version"
echo "是否要更换为 5.0.4 版本？"
read -p "请输入 y 选择是，n 选择否 (y/n)，回车键确定: " choice
case "$choice" in
    [Yy]* )
        echo "用户选择继续升级到 5.0.4 版本"
        ;;
    [Nn]* )
        echo "用户选择取消升级，脚本停止执行"
        exit 0
        ;;
    * )
        echo "无效输入，脚本停止执行"
        exit 1
        ;;
esac


# 检测操作系统类型和版本
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$ID"
    OS_VERSION="$VERSION_ID"
else
    echo "错误：无法检测操作系统信息"
    exit 1
fi

# 检查是否支持的操作系统
case "$OS_NAME" in
    "debian")
        DEBIAN_MAJOR_VERSION=$(echo $OS_VERSION | cut -d. -f1)
        if [ "$DEBIAN_MAJOR_VERSION" -lt 10 ]; then
            echo "错误：此脚本仅支持 Debian 10+ 系统"
            echo "当前系统版本：Debian $OS_VERSION"
            echo "请升级到 Debian 10 或更高版本"
            exit 1
        fi
        ;;
    "ubuntu")
        UBUNTU_MAJOR_VERSION=$(echo $OS_VERSION | cut -d. -f1)
        UBUNTU_MINOR_VERSION=$(echo $OS_VERSION | cut -d. -f2)
        if [ "$UBUNTU_MAJOR_VERSION" -lt 20 ] || ([ "$UBUNTU_MAJOR_VERSION" -eq 20 ] && [ "$UBUNTU_MINOR_VERSION" -lt 4 ]); then
            echo "错误：此脚本仅支持 Ubuntu 20.04+ 系统"
            echo "当前系统版本：Ubuntu $OS_VERSION"
            echo "请升级到 Ubuntu 20.04 或更高版本"
            exit 1
        fi
        ;;
    *)
        echo "错误：此脚本仅支持以下操作系统："
        echo "1. Debian 10+"
        echo "2. Ubuntu 20.04+"
        echo "当前系统：$OS_NAME $OS_VERSION"
        exit 1
        ;;
esac

# 在 home 目录中搜索所有 /.config/qBittorrent/ 文件夹
qbittorrent_dirs=$(find /home -type d -name ".config" -exec find {} -type d -name "qBittorrent" \; 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "错误：搜索 qBittorrent 配置文件夹失败"
    exit 1
fi
if [ -n "$qbittorrent_dirs" ]; then
    # 从路径中提取用户名
    users=()
    while IFS= read -r dir; do
        if [[ "$dir" =~ /home/([^/]+)/.config/qBittorrent ]]; then
            user="${BASH_REMATCH[1]}"
            users+=("$user")
        fi
    done <<< "$qbittorrent_dirs"
    
    # 使用第一个用户作为默认用户
    if [ ${#users[@]} -gt 0 ]; then
        USER="${users[0]}"
        echo "将使用用户：$USER"
    fi
else
    echo "错误：未找到任何 qBittorrent 配置文件夹"
    echo "请确保系统中已安装 qBittorrent 或存在用户配置"
    exit 1
fi

# 运行 systemctl 命令查找 qb 相关服务
qb_services=$(systemctl list-units --all | grep -i qb)
if [ $? -ne 0 ]; then
    echo "错误：查找 qBittorrent 相关服务失败"
    exit 1
fi

# 从输出中搜索以 qbittorrent-nox@ 开头的服务名字
qbittorrent_nox_services=$(echo "$qb_services" | grep -E "qbittorrent-nox@")

if [ -n "$qbittorrent_nox_services" ]; then
    # 检查是否包含当前用户的服务
    target_service="qbittorrent-nox@$USER.service"
    if ! echo "$qbittorrent_nox_services" | grep -q "$target_service"; then
        echo "错误：未找到目标服务 $target_service"
        exit 1
    fi
    
    # 停止 qbittorrent-nox@$USER.service 服务
    systemctl stop "qbittorrent-nox@$USER.service"
    if [ $? -ne 0 ]; then
        echo "错误：停止服务 qbittorrent-nox@$USER.service 失败"
        exit 1
    fi
else
    echo "未找到 qbittorrent 服务，请检查是否安装"
    exit 1
fi


# 检测系统架构
systemARCH=$(uname -m)
if [ $? -ne 0 ]; then
    echo "错误：检测系统架构失败"
    exit 1
fi

# 直接下载 qBittorrent 二进制文件到 /usr/bin/ 目录
echo "正在下载 qBittorrent 到 /usr/bin/ 目录..."
if [[ $systemARCH == x86_64 ]]; then
    wget -q -O /usr/bin/qbittorrent-nox https://raw.githubusercontent.com/guowanghushifu/Seedbox-Components/refs/heads/main/Torrent%20Clients/qBittorrent/x86_64/qBittorrent-5.0.4%20-%20libtorrent-v1.2.20/qbittorrent-nox
    if [ $? -ne 0 ]; then
        echo "错误：下载 x86_64 版本 qBittorrent 失败"
        exit 1
    fi
elif [[ $systemARCH == aarch64 ]]; then
    wget -q -O /usr/bin/qbittorrent-nox https://raw.githubusercontent.com/guowanghushifu/Seedbox-Components/refs/heads/main/Torrent%20Clients/qBittorrent/ARM64/qBittorrent-5.0.4%20-%20libtorrent-v1.2.20/qbittorrent-nox
    if [ $? -ne 0 ]; then
        echo "错误：下载 ARM64 版本 qBittorrent 失败"
        exit 1
    fi
else
    echo "错误：不支持的系统架构 $systemARCH"
    exit 1
fi

# 设置执行权限
chmod +x /usr/bin/qbittorrent-nox
if [ $? -ne 0 ]; then
    echo "错误：设置执行权限失败"
    exit 1
fi


# Create systemd services
if test -e /etc/systemd/system/qbittorrent-nox@.service; then
    rm /etc/systemd/system/qbittorrent-nox@.service
fi
touch /etc/systemd/system/qbittorrent-nox@.service
cat << EOF >/etc/systemd/system/qbittorrent-nox@.service
[Unit]
Description=qBittorrent
After=network.target

[Service]
Type=exec
User=$USER
LimitNOFILE=infinity
ExecStart=/usr/bin/qbittorrent-nox
Restart=on-failure
TimeoutStopSec=10
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "qBittorrent 安装完成！"

# 重新加载 systemd 配置
systemctl daemon-reload

# 启动 qBittorrent 服务
systemctl start "qbittorrent-nox@$USER.service"

# 设置服务开机自启
systemctl enable "qbittorrent-nox@$USER.service"

# 查看服务状态
echo "正在查看 qBittorrent 服务状态..."
systemctl status "qbittorrent-nox@$USER.service" --no-pager

echo "脚本执行完成！"
