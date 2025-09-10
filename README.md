# qBittorrent 5.0.4 自动升级脚本

## 项目简介

这是一个用于自动升级 qBittorrent 到 5.0.4 版本的 Bash 脚本。该脚本支持 Debian 10+ 和 Ubuntu 20.04+ 系统，能够自动检测现有安装、下载新版本并配置 systemd 服务。

## 功能特性

- ✅ 自动检测系统兼容性（Debian 10+ / Ubuntu 20.04+）
- ✅ 检测现有 qBittorrent 安装和用户配置
- ✅ 支持 x86_64 和 ARM64 架构
- ✅ 自动停止现有服务
- ✅ 下载并安装 qBittorrent 5.0.4 (libtorrent 1.2.20)
- ✅ 创建 systemd 服务配置
- ✅ 设置开机自启动
- ✅ 显示服务运行状态

## 系统要求

- **操作系统**: Debian 10+ 或 Ubuntu 20.04+
- **架构**: x86_64 或 ARM64 (aarch64)
- **权限**: 需要 root 权限
- **网络**: 需要互联网连接下载二进制文件

## 使用方法

### 一键安装

```bash
bash <(wget -qO- https://raw.githubusercontent.com/doloroustang/qb504/main/qb504.sh)
```

## 使用说明

1. **运行前确认**: 脚本会检查当前 qBittorrent 版本并询问是否继续升级
2. **系统检测**: 自动检测操作系统类型和版本兼容性
3. **用户检测**: 自动搜索并识别 qBittorrent 配置目录
4. **服务管理**: 自动停止现有服务，安装新版本后重新启动
5. **权限设置**: 自动设置正确的文件权限和服务配置

## 注意事项

- ⚠️ 脚本运行失败时会立即退出，请确保系统满足要求
- ⚠️ 建议在升级前备份重要的 qBittorrent 配置
- ⚠️ 脚本会替换现有的 qBittorrent 二进制文件
- ⚠️ 需要确保系统有足够的磁盘空间

## 故障排除

### 常见问题

1. **权限错误**: 确保使用 `sudo` 运行脚本
2. **系统不兼容**: 检查系统版本是否符合要求
3. **网络问题**: 确保网络连接正常，能够访问 GitHub
4. **服务启动失败**: 检查端口是否被占用，查看 systemd 日志

### 查看服务状态

```bash
# 查看服务状态
systemctl status qbittorrent-nox@用户名.service

# 查看服务日志
journalctl -u qbittorrent-nox@用户名.service -f
```

## 致谢

感谢 [@guowanghushifu](https://github.com/guowanghushifu) 提供的 qBittorrent 二进制文件，本脚本中的 qBittorrent 5.0.4 二进制文件来源于其 [Seedbox-Components](https://github.com/guowanghushifu/Seedbox-Components) 仓库。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个脚本。

---

**免责声明**: 使用此脚本前请确保了解其功能，建议在测试环境中先行验证。作者不对使用此脚本造成的任何损失承担责任。
