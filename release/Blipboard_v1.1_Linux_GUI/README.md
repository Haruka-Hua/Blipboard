# Blipboard Linux GUI

此目录包含可在 Linux 上分发的 GUI 构件。

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

## 主要功能

- **地址缓存**：Client 页会记住上次连接的服务器地址与端口。地址栏留空、直接点击 Connect 即可重连上次的服务器，无需重新输入。
- **端口可选**：Server 页提供「Use a random available port」开关，在固定 4 号通道被其他蓝牙服务占用时仍能正常启动（实际端口会打印在日志中）；Client 页新增 Port 输入框，填写服务器实际监听的通道号（默认 4，范围 1–30）。
- **Push / Pull 按钮**：Client 连接建立后，可直接点击页面上的 Push / Pull 按钮推送 / 拉取剪贴板，与快捷键等效，无需记住按键组合。

## 自定义快捷键

Client 的推送 / 拉取快捷键默认为 `ctrl+alt+c` / `ctrl+alt+v`，可通过 `config.json` 修改。Client 首次启动时会自动生成默认配置文件：

```json
{
  "hotkeys": {
    "push": "ctrl+alt+c",
    "pull": "ctrl+alt+v"
  }
}
```

配置文件按以下顺序查找：

1. 可执行文件同目录（便携安装，目录可写时优先）；
2. `~/.config/blipboard/config.json`（AppImage 为只读挂载，会自动改用此处）。

快捷键格式与 [keyboard](https://github.com/boppreh/keyboard) 库一致（如 `ctrl+shift+insert`）。无效的配置会回退默认值，并在 Client 日志中给出警告。

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

## 已知问题

- Linux 端 Client 在部分环境下需要额外权限（键盘监听 / 蓝牙套接字），如遇快捷键无响应，请参照上方 `setcap` 说明或以 root 运行排查。
