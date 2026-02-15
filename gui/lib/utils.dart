import 'dart:io';
import "package:flutter/material.dart";

String getPythonPath() {
  String rootPath = Directory.current.parent.path; 

  if (Platform.isWindows) {
    return "$rootPath\\core\\.venv\\Scripts\\python.exe";
  } else {
    return "$rootPath/core/.venv/bin/python";
  }
}

String getWorkingDir(){
  String rootPath = Directory.current.parent.path; 

  if (Platform.isWindows) {
    return "$rootPath\\core";
  } else {
    return "$rootPath/core";
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

