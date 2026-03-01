# 🚀 快速开始 (Quick Start)

欢迎使用 **Blipboard v1.1**！这是一个基于蓝牙的跨设备剪贴板同步工具。

---

## 🪟 Windows
Windows 版本支持图形界面和命令行，无需安装点击即可使用。
### 硬件及系统要求
你的电脑应该安装了蓝牙模块并且确保蓝牙服务打开，建议在 Windows 10/11 下使用。

### 下载 Blipboard
在仓库页面点击右侧的`Releases`，下载`Blipboard_v1.1_Win.zip`并解压。

### 启动软件
在解压后的文件夹中，找到并双击 **`Blipboard.exe`**。
*(注意：请确保 `core` 和 `data` 文件夹与主程序在同一目录下，否则无法运行)*

### 连接两台电脑
你需要两台支持蓝牙的 Windows 电脑，一台作为 **Server**（服务端），另一台作为 **Client**（客户端）。

#### 🖥️ 服务端 (Server)
1. 在第一台电脑上运行 `Blipboard.exe`。
2. 点击 **"Start as Server"**。
3. 点击 **"Start Server"** 按钮。
4. 等待几秒，界面上方会出现 **Local Server MAC Address**（本机蓝牙地址），点击复制图标复制该地址。

#### 💻 客户端 (Client)
1. 在第二台电脑上运行 `Blipboard.exe`。
2. 点击 **"Start as Client"**。
3. 在输入框中粘贴（或手动输入）Server 端的蓝牙地址（格式如 `11:45:14:19:19:81`）。
4. 点击 **"Connect"**。

### ⌨️ 命令行高级用法 (CLI)

如果你更喜欢使用命令行，或者希望在后台运行，可以直接使用 `core` 文件夹下的工具。

1. 进入 `core` 文件夹。
2. **服务端**：双击运行 `blipboard_server.exe`。
3. **客户端**：双击运行 `blipboard_client.exe`，并根据提示输入 Server 地址。

---

## 🐧 Linux

Linux 版本现在提供 **GUI (AppImage)** 和 **CLI (命令行)** 两种方式。

### 准备工作 (Dependencies)
无论使用哪种版本，请确保你的系统安装了以下依赖：
- `bluez`、`bluez-utils` (用于蓝牙连接)
- `xclip` 或 `xsel` (用于剪贴板操作)
- `python3` (CLI 版本需要)

在 Debian/Ubuntu 系统中，你可以运行：
```bash
sudo apt update && sudo apt install bluez xclip python3
```

---

### 🖥️ 图形界面版 (GUI - AppImage)
推荐普通用户使用。
1. 下载 **`Blipboard_v1.1_Linux_GUI.zip`** 并解压。
2. 赋予 `Blipboard.AppImage` 执行权限：
   ```bash
   chmod +x Blipboard.AppImage
   ```
3. 双击运行即可。

*(提示：如果无法启动，请尝试运行 `./install.sh` 来自动安装系统依赖并设置权限)*

---

### ⌨️ 命令行版 (CLI - Scripts)
适用于无桌面环境或希望在后台运行的用户。
1. 下载 **`Blipboard_v1.1_Linux_CLI.zip`** 并解压。
2. 赋予脚本执行权限：
   ```bash
   chmod +x install.sh run_server.sh run_client.sh
   ```
3. **初始化环境** (首次运行)：
   ```bash
   ./install.sh
   ```
4. **启动软件**：
   - **服务端**：`./run_server.sh` (显示并复制 MAC 地址)
   - **客户端**：`sudo ./run_client.sh` (输入服务端 MAC 地址)

---

## 🐍 Raw Version (源码运行)

如果你想直接使用Python源码并进行修改，或者想自己在其他平台运行，请参考以下步骤。

### 下载 Python 源代码
在仓库页面点击右侧的`Releases`，下载`Blipboard_v1.1_Raw.zip`并解压。

### 环境要求
- Python 3.x 解释器
- 支持蓝牙的硬件设备

### 创建虚拟环境
推荐使用虚拟环境以避免污染全局依赖：

**Windows:**
```bash
python -m venv .venv
.venv\Scripts\Activate.ps1
```

**Linux/macOS:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 安装依赖
```bash
pip install -r requirements.txt
```

### 运行程序
**Server 端:**
```bash
python blipboard_server.py
```

**Client 端:**
*(注意：Linux 下监听全局键盘可能需要 sudo 权限)*
```bash
python blipboard_client.py
```
启动后根据提示输入 Server 的 MAC 地址即可。

---
