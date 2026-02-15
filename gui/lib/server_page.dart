import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "dart:io";
import "dart:convert";
import "utils.dart";

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage>{
  List<String> logs = [];
  Process? _activeProcess;
  bool _isServiceRunning = false;
  String _localMac = "Unknown";
  final ScrollController _scrollController = ScrollController();

  void _stopServer(){
    if (_activeProcess != null){
      _activeProcess!.kill();
      setState((){
        _isServiceRunning = false;
        _activeProcess = null;
        logs.add("[System] Server process stopped.");
      });
    }
  }

  void _startServer() async {
    String pythonPath = getPythonPath(targetExe: "blipboard_server.exe");
    String workingDir = getWorkingDir();
    bool isBundledExe = pythonPath.endsWith(".exe") && !pythonPath.contains("python.exe");

    setState((){
      logs.add("Starting server ...");
      logs.add("Path: $pythonPath");
      logs.add("Working Dir: $workingDir"); // Debug info
    });
    
    try{
      // 检查文件是否存在
      if (!File(pythonPath).existsSync()) {
        throw Exception("Executable not found: $pythonPath");
      }

      var process = await Process.start(
        pythonPath,
        isBundledExe ? [] : ["-u","blipboard_server.py"],
        workingDirectory: workingDir,
        runInShell: false, // Explicitly set runInShell
      );
      setState((){
        _activeProcess = process;
        _isServiceRunning = true;
      });
            process.exitCode.then((code){
        setState((){
          _isServiceRunning = false;
          _activeProcess = null;
          logs.add("[System] Python process stopped (code: $code)\n");
        });
      });
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((data){
        setState((){
          if(data.contains("Server MAC address:")){
            //todo
            _localMac = data.split(" ").last.trim();
          }
          logs.add(data.trim());
        });
        scrollToBottom(_scrollController);
      });
      process.stderr.transform(utf8.decoder).listen((data){
        setState((){
          logs.add("Error: ${data.trim()}");
        });
      });
    } catch(e){
      logs.add("Failed to start python script, please check path: $e");
    }
  }

  @override
  void dispose(){
    _scrollController.dispose();
    if(_activeProcess!=null){
      _activeProcess!.kill();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("Blipboard Server",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
        ),
        foregroundColor: const Color(0xff0082fc),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff0082fc).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff0082fc).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    "Local Server MAC Address:",
                    style: TextStyle(color: Colors.grey, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _localMac,
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold,
                          fontFamily: "monospace",
                        ),
                      ),
                      IconButton(
                        onPressed: (){
                          Clipboard.setData(ClipboardData(text:_localMac));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("MAC Address copied!"),
                          ));
                        },
                        icon: const Icon(Icons.copy, size: 20),
                      )
                    ],
                  ),
                  const Text(
                    "Start service to detect MAC", 
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isServiceRunning ? _stopServer : _startServer,
                      icon: Icon(_isServiceRunning ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
                      label: Text(_isServiceRunning ? "Stop Server" : "Start Server"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _isServiceRunning ? Colors.redAccent : Color(0xff0082fc),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "SERVER LOG",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width:double.infinity,
                padding:const EdgeInsets.all(10),
                decoration:BoxDecoration(
                  color: Color.fromARGB(255, 48, 10, 36),
                  borderRadius:BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withValues(alpha:0.3)),
                  boxShadow: [
                    BoxShadow(
                      color:Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0,4),
                    ),
                  ],
                ),
                child:ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.5),
                    ),
                    thickness: WidgetStateProperty.all(8.0),
                    radius: const Radius.circular(10),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility:  true,
                    trackVisibility: true,
                    thickness: 6.0,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            logs.join("\n"),
                            style: const TextStyle(
                              color: Color(0xffd3d7cf),
                              fontFamily: "Consolas",
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height:10),
          ],
        )
      ),
    );
  }
}