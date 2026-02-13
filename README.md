# 📋 Blipboard
## 💡 项目说明
你有没有遇到过这种情况？你正在同时使用两台电脑进行协作，或许其中一台翻墙到外网使用AI，另一台连着校园网正在查文献或者在跟命令行斗智斗勇？这个时候，你或许特别希望两台电脑能够共享同一个剪贴板，这样就可以把文献或报错贴给AI，或者把AI提供的命令贴到命令行？

遗憾的是，现在大部分的共享剪贴板项目都依赖同一局域网，这对于正在翻墙的你来说可能不是很好用。有没有一种不需要在同一网络环境下，甚至不需要联网的解决方案呢？

Blipboard正是一个为此而生的项目。这是一个基于蓝牙的共享剪贴板项目，只要两台电脑能够通过蓝牙连接，Blipboard就可以工作！

这是我的一个编程练习项目，可能存在一些不成熟的代码实现，还望多多指教！

## 🚀 快速开始
### Windows
#### 硬件及系统要求
支持蓝牙的64位机器，安装了Windows 10/11系统。
#### 安装Python解释器
你的电脑上需要安装一个Python解释器，最简单快速的方法是去Microft Store上安装一个，这样可以不需要自己配置环境变量。
#### 获取Python脚本
在仓库页面点击右侧的"Releases"，下载"Source Code (zip)"并解压，在解压后的目录中右键->在终端中打开。
#### 创建虚拟环境
第一次使用时，需要创建虚拟环境（如果你不介意你的全局环境变得非常臃肿的话，可以跳过这一步）：
```bash
python -m venv .venv
```
如果创建了虚拟环境，每次前使用记得激活虚拟环境：
```bash
.venv\Scripts\Activate.ps1
```
#### 安装依赖项
第一次使用时，需要安装依赖：
```bash
.venv\Scripts\python.exe -m pip install -r requirements.txt
```
#### 开始使用
在两台电脑上都完成这些操作后，你就可以开始使用Blipboard了！你需要选择其中的一台作为server，另一台作为client，并让他们通过蓝牙连接。

在server上，运行`blipboard_server.py`：
```bash
.venv\Scripts\python.exe blipboard_server.py
```

在client上，运行`blipboard_client.py`：
```bash
.venv\Scripts\python.exe blipboard_client.py
```

启动client后，需要手动输入server的MAC地址。server启动时会打印出自己的蓝牙地址，直接填写过去即可。

现在你就可以开始使用 **Blipboard** 了，你可以在client上使用热键手动进行剪贴板的同步：
|热键|功能|
|---|---|
|Ctrl+Alt+C|将client的剪贴板同步给server|
|Ctrl+Alt+V|将server的剪贴板同步给client|

在运行窗口中使用Ctrl+C可以退出client或者server。

### Linux
#### 硬件及系统要求
支持蓝牙的64位机器，安装了任何可以正常使用的Linux发行版，最好有图形界面，因为目前在终端中使用热键容易发生冲突。
#### 安装python解释器
一般来说，debian系的发行版都自带了python，可以用以下命令检测python版本：
```bash
python3 --version
```
如果没有返回内容，则需要安装python，以apt安装为例：
```bash
sudo apt update
sudo apt install python3
```
#### 获取Python脚本
在仓库页面点击右侧的"Releases"，下载"Source Code"并解压，在解压后的目录中打开终端。
#### 创建虚拟环境
第一次使用时，需要创建虚拟环境（如果你不介意你的全局环境变得非常臃肿的话，可以跳过这一步）：
```bash
python -m venv .venv
```
如果创建了虚拟环境，每次前使用记得激活虚拟环境：
```bash
source ./.venv/bin/activate
```
#### 安装依赖项
第一次使用时，需要安装依赖：
```bash
pip install -r requirements.txt
```
#### 开始使用
在两台电脑上都完成这些操作后，你就可以开始使用Blipboard了！你需要选择其中的一台作为server，另一台作为client，并让他们通过蓝牙连接。

在server上，运行`blipboard_server.py`：
```bash
./.venv/bin/python ./blipboard_server.py
```

在client上，运行`blipboard_client.py`，因为client使用了全局键盘监听，请确保你能够使用root权限：
```bash
sudo ./.venv/bin/python ./blipboard_client.py
```

启动client后，需要手动输入server的MAC地址。server启动时会打印出自己的蓝牙地址，直接填写过去即可。

现在你就可以开始使用 **Blipboard** 了，你可以在client上使用热键手动进行剪贴板的同步：
|热键|功能|
|---|---|
|Ctrl+Alt+C|将client的剪贴板同步给server|
|Ctrl+Alt+V|将server的剪贴板同步给client|

在运行终端中使用Ctrl+C可以退出client或者server。

## 📁 项目结构
```
Blipboard/
├── blipboard_client.py
├── blipboard_server.py
├── protocol/
│   ├── protocol.py
│   └── protocol.md
├── requirements.txt
├── README.md
└── .gitignore
```

## 📄 版本日志
|版本|更新时间|更新日志|
|---|---|---|
|v0.3|2026/02/14|改进了传输协议，支持长文本同步|
|v0.2|2026/02/11|实现了双向手动传输，通过绑定热键实现|
|v0.1|2026/02/10|实现了Windows设备之间的通信，server可以同步client的剪贴板，但是只能单向传输，client无法同步server的剪贴板，预计下个版本中完善|

## 🤝 贡献
欢迎提交 Issue 和 Pull Request！如果你发现任何问题或有改进建议，请：
1. 查看 [Issues](https://github.com/Haruka-Hua/Blipboard/issues) 是否已有类似问题
2. 创建新的 Issue 描述问题
3. 或者直接提交 Pull Request

**Happy Coding!** 🎉 如果你觉得这个项目有用，请给个 ⭐ Star！