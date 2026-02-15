# 📋 Blipboard
## 💡 项目说明
你有没有遇到过这种情况？你正在同时使用两台电脑进行协作，或许其中一台翻墙到外网使用AI，另一台连着校园网正在查文献或者在跟命令行斗智斗勇？这个时候，你或许特别希望两台电脑能够共享同一个剪贴板，这样就可以把文献和报错贴给AI，或者把AI提供的命令贴到命令行？

遗憾的是，现在大部分的共享剪贴板项目都依赖同一局域网，这对于正在翻墙的你来说可能不是很好用。有没有一种不需要在同一网络环境下，甚至不需要联网的解决方案呢？

Blipboard正是一个为此而生的项目。这是一个基于蓝牙的共享剪贴板项目，只要两台电脑能够通过蓝牙连接，Blipboard就可以工作！

这是我的一个编程练习项目，可能存在一些不成熟的代码实现，还望多多指教！

## 🚀 快速开始
见 **[QuickStart.md](QuickStart.md)**.

目前我已经为 Windows 制作了图形界面和免安装环境的命令行版本，打开即可使用。

Linux 端提供了简单的安装脚本和启动脚本，运行脚本即可使用。

如果你追求运行效率，或者想要利用源代码做一些定制，也可以下载 Raw 版本使用 Python 源代码。

Mac OS 暂时不支持，因为我没有苹果电脑，你可以自行使用 Python 解释器运行 Raw 版本。

## 📁 项目结构
```
Blipboard/
├── README.md
├── QuickStart.md
├── LICENSE
├── .gitignore
├── build_v1.0.py
├── core/
│   ├── blipboard_server.py
│   ├── blipboard_client.py
│   ├── requirements.txt
│   ├── transmission/
│   │   ├── protocol.md
│   │   └── transmission.py
├── gui/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── server_page.dart
│   │   ├── client_page.dart
│   │   └── utils.dart
│   ├── windows/
│   ├── linux/
│   ├── android/
│   ├── ios/
│   └── macos/
```

## 📄 版本日志
|版本|更新时间|更新日志|
|---|---|---|
|v1.0|2026/02/16|第一个正式发行版，完成 Windows GUI 的制作，修复Linux获取mac地址可能存在的问题，进行打包分发|
|v0.4|2026/02/14|连接失败或断开时自动尝试重连|
|v0.3|2026/02/14|改进了传输协议，支持长文本同步|
|v0.2|2026/02/11|实现了双向手动传输，通过绑定热键实现|
|v0.1|2026/02/10|实现了Windows设备之间的通信，server可以同步client的剪贴板，但是只能单向传输，client无法同步server的剪贴板，预计下个版本中完善|

## 🤝 贡献
欢迎提交 Issue 和 Pull Request！如果你发现任何问题或有改进建议，请：
1. 查看 [Issues](https://github.com/Haruka-Hua/Blipboard/issues) 是否已有类似问题
2. 创建新的 Issue 描述问题
3. 或者直接提交 Pull Request

**Happy Coding!** 🎉 如果你觉得这个项目有用，请给个 ⭐ Star！