# Blipboard
## 项目说明

**Blipboard** 是一个共享剪贴板项目，通过蓝牙实现设备间的剪贴板数据传输，无需设备处于同一局域网环境，且保证了数据安全。该项目适用于内网——外网环境间的设备协作，公共网络环境下数据的安全传输，以及离线环境下的跨设备协作。

## 使用方式

Blipboard 通过 server-client 模式实现剪贴板共享。在您需要协作的两台设备中，一台作为 **client**， 需要启动相应的 client 程序，主动发送推送和拉取剪贴板请求；另一台作为 **server**，需要启动相应的 server 程序，负责处理 client 发送的请求。

Blipboard 提供了命令行版本和图形界面版本，供您挑选使用。具体使用方式请参考 [快速开始](doc/quickstart/QUICKSTART.md) 。

其中，命令行版本支持 Windows/Linux/MacOS ，图形界面版本支持 Windows/Linux 。Linux 的图形界面版本对于 server 的支持目前存在一些问题，需要在 Linux 上启动 server 的朋友建议先暂时使用命令行版本。

## 项目结构
```
Blipboard/
├── README.md
├── QuickStart.md
├── LICENSE
├── .gitignore
├── doc/
│   └── quickstart/
│       ├── QUICKSTART.md
│       └──...
├── core/
│   ├── blipboard_server.py
│   ├── blipboard_client.py
│   ├── requirements.txt
│   ├── transmission/
│   │   ├── protocol.md
│   │   └── transmission.py
│   └── socket_test/
├── gui/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── server_page.dart
│   │   ├── client_page.dart
│   │   └── utils.dart
│   └── ... (multi-platform support)
├── release/ (Build artifacts)
├── tools/
│   ├── build_v1.1.py
│   ├── build_core_pyinstaller.sh
│   └── make_appimage.sh
└── tmp/
```

## 版本日志
|版本|更新时间|更新日志|
|---|---|---|
|v1.1|2026/03/02|完成Linux GUI的制作，修复图标错误，进行打包分发|
|v1.0|2026/02/16|第一个正式发行版，完成 Windows GUI 的制作，修复Linux获取mac地址可能存在的问题，进行打包分发|
|v0.4|2026/02/14|连接失败或断开时自动尝试重连|
|v0.3|2026/02/14|改进了传输协议，支持长文本同步|
|v0.2|2026/02/11|实现了双向手动传输，通过绑定热键实现|
|v0.1|2026/02/10|实现了Windows设备之间的通信，server可以同步client的剪贴板，但是只能单向传输，client无法同步server的剪贴板，预计下个版本中完善|

## 贡献
欢迎提交 Issue 和 Pull Request！如果你发现任何问题或有改进建议，请：
1. 查看 [Issues](https://github.com/Haruka-Hua/Blipboard/issues) 是否已有类似问题
2. 创建新的 Issue 描述问题
3. 或者直接提交 Pull Request

**Happy Coding!** 🎉 如果你觉得这个项目有用，请给个 ⭐ Star！