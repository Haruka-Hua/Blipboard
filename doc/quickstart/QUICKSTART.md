# 🚀 快速开始 (Quick Start)

欢迎使用 **Blipboard**！这是一个基于蓝牙的跨设备剪贴板同步工具。

---

## 🪟 Windows
Windows 版本支持图形界面和命令行，无需安装点击即可使用。
### 硬件及系统要求
你的电脑应该安装了蓝牙模块并且确保蓝牙服务打开，建议在 Windows 10/11 下使用。

### 下载 Blipboard
在仓库页面点击右侧的`Releases`，下载`Blipboard_v1.1_Win.zip`并解压。

### 使用图形界面 (GUI)
在解压后的文件夹中，找到并双击 **`Blipboard.exe`**。
*(注意：请确保 `core` 和 `data` 文件夹与主程序在同一目录下，否则无法运行)*

#### 🖥️ 服务端 (Server)
1. 点击 **"Start as Server"**。
2. 点击 **"Start Server"** 按钮。
3. 等待几秒，界面上方会出现 **Local Server MAC Address**（本机蓝牙地址），点击复制图标复制该地址。

#### 💻 客户端 (Client)
1. 点击 **"Start as Client"**。
2. 在输入框中粘贴（或手动输入）Server 端的蓝牙地址（格式如 `11:45:14:19:19:81`）。
3. 点击 **"Connect"**。

### 使用命令行 (CLI)

如果你更喜欢使用命令行，或者希望在后台运行，可以直接使用 `core` 文件夹下的工具。

1. 进入 `core` 文件夹。
2. **服务端**：双击运行 `blipboard_server.exe`。
3. **客户端**：双击运行 `blipboard_client.exe`，并根据提示输入 Server 地址。

---

## 🐧 Linux

Linux 版本现在提供 **图形界面 (AppImage)** 和 **命令行 (Scripts)** 两种方式。

### 准备工作
无论使用哪种版本，请确保你的系统安装了以下依赖：
- `bluez`、`bluez-utils` (用于蓝牙连接)
- `xclip` 或 `xsel` (用于剪贴板操作)
- `python3` (CLI 版本需要)

在 Debian/Ubuntu 系统中，你可以运行：
```bash
sudo apt update && sudo apt install bluez xclip python3
```
然后从 `Releases` 下载 `Blipboard_v1.1_Linux_CLI.zip` 并解压。

---

### 使用图形界面 (GUI)

1. 赋予 `Blipboard.AppImage` 执行权限：
   ```bash
   chmod +x Blipboard.AppImage
   ```
2. 双击运行即可。

---

### 使用命令行 (Scripts)
推荐在 Linux 上使用命令行版本。
1. 下载 `Blipboard_v1.1_Linux_CLI.zip` 并解压。
2. 赋予脚本执行权限：
   ```bash
   chmod +x install.sh run_server.sh run_client.sh
   ```
3. 首次运行时，需要配置环境，我们为您提供了初始化脚本，直接运行即可：
   ```bash
   ./install.sh
   ```
4. 启动服务：
   - **服务端**：
   ```bash
   ./run_server.sh
   ```
   - **客户端**：需要root权限以监听热键
   ```bash
   sudo ./run_client.sh
   ``` 

---

## 🐍 Raw Version (源码运行)

如果你想直接使用Python源码并进行修改，或者想在MacOS等其他平台运行，请参考以下步骤。

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

*可能需要 sudo 权限*
```bash
python blipboard_client.py
```
启动后根据提示输入 Server 的 MAC 地址即可。

---

## 推送/拉取您的剪贴板
连接完成后，在 client 上使用 `ctrl + alt + c` 将剪贴板内容推送给 server， 使用`ctrl + alt + v` 拉取 server 的剪贴板内容。