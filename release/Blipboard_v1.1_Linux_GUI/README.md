# Blipboard Linux GUI

此目录包含可在 Linux 上分发的GUI构件。

- `Blipboard.AppImage`：自包含的应用程序包。赋予执行权限后即可运行。
- `install.sh`：可选的辅助脚本，用于安装系统依赖并设置权限。

## 使用方法
1. 将 `Blipboard.AppImage` 复制到 Linux 机器上。
2. 赋予执行权限：
   ```bash
   chmod +x Blipboard.AppImage
   ```
3. 直接运行：
   ```bash
   ./Blipboard.AppImage
   ```
   或者将其移动到 `/opt/blipboard/` 等位置进行安装。

## 依赖项
包中包含了 Flutter GUI 和 Python 可执行程序，但系统需提供：

- `bluez`、`bluez-utils`（用于 RFCOMM 蓝牙套接字）
- `xclip` 或 `xsel`（`pyperclip` 的剪贴板功能依赖）
- GTK+ 3 库（大多数桌面环境默认提供）

可选地，为在非 root 下运行，可能需要授予二进制权限：

```bash
sudo setcap 'cap_net_raw,cap_net_admin+eip' /path/to/blipboard_server
```

捆绑的 `install.sh` 可以在 Debian/Ubuntu 上安装上述依赖。
