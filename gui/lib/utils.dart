import 'dart:io';
import "package:flutter/material.dart";
import "package:path/path.dart" as p;

String getPythonPath({String? targetExe}) {
  String exePath = Platform.resolvedExecutable;
  String appDir = Directory(exePath).parent.path;
  
  // Debug Mode: Running from VS Code / flutter run
  if (appDir.toLowerCase().contains("debug")) {
     String rootPath = Directory.current.parent.path;
     // for Windows
     if (Platform.isWindows) {
      return p.join(rootPath,"core",".venv","Scripts","python.exe");
     }
     // for Linux and macOS
     else if (Platform.isLinux || Platform.isMacOS) {
      return p.join(rootPath,"core",".venv","bin","python");
     }
  }

  // Release Mode: Bundled executable in ./core/
  if (targetExe != null) {
      String fullPath = p.join(appDir, "core", targetExe);
      // Fallback: Check if file exists, if not, maybe it's in a subdirectory?
      // But for our release structure, it should be in core/
      return fullPath;
  }

  if(Platform.isWindows){
    return p.join(appDir,"core","python","python.exe");
  } else if (Platform.isLinux || Platform.isMacOS) {
    String candidate = p.join(appDir,"core","python3");
    if(File(candidate).existsSync()) return candidate;
    return "python3";
  } else {
    return "python";
  }
}

String getWorkingDir(){
  String exePath = Platform.resolvedExecutable;
  String appDir = Directory(exePath).parent.path;

  // Debug Mode
  if (appDir.toLowerCase().contains("debug")) {
    String rootPath = Directory.current.parent.path;
    return p.join(rootPath,"core");
  }
  // Release Mode: Working directory should be the folder containing the exe
  return p.join(appDir,"core");
}

String exeName(String base) =>
    Platform.isWindows ? '$base.exe' : base;

bool isBundledExePath(String path){
  final name = path.split(Platform.pathSeparator).last.toLowerCase();
  if(Platform.isWindows){
    return name.endsWith(".exe") && !name.contains("python.exe");
  } else {
    return name == "blipbooard_server" || name == "blipboard_client";
  }
}

void scrollToBottom(ScrollController scrollController){
  bool isAtBottom = scrollController.hasClients &&
    scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50;
  if(isAtBottom) {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(scrollController.hasClients){
          scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

