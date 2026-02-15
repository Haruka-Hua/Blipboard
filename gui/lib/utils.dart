import 'dart:io';
import "package:flutter/material.dart";

String getPythonPath({String? targetExe}) {
  String exePath = Platform.resolvedExecutable;
  String appDir = Directory(exePath).parent.path;
  
  // Debug Mode: Running from VS Code / flutter run
  if (appDir.contains("Debug")) {
     String rootPath = Directory.current.parent.path;
     return "$rootPath\\core\\.venv\\Scripts\\python.exe";
  }

  // Release Mode: Bundled exe in ./core/
  if (targetExe != null) {
      String fullPath = "$appDir\\core\\$targetExe";
      // Fallback: Check if file exists, if not, maybe it's in a subdirectory?
      // But for our release structure, it should be in core/
      return fullPath;
  }

  return "$appDir\\core\\python\\python.exe"; 
}

String getWorkingDir(){
  String exePath = Platform.resolvedExecutable;
  String appDir = Directory(exePath).parent.path;

  // Debug Mode
  if (appDir.contains("Debug")) {
    String rootPath = Directory.current.parent.path;
    return "$rootPath\\core";
  }
  
  // Release Mode: Working directory should be the folder containing the exe
  return "$appDir\\core";
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

