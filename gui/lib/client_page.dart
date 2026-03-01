import "package:flutter/material.dart";
import "dart:io";
import "dart:convert";
import "utils.dart";

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final TextEditingController _macController = TextEditingController();
  List<String> logs = [];
  Process? _activeProcess;
  bool _isConnecting = false;
  final ScrollController _scrollController = ScrollController();

  void _stopClient(){
    if(_activeProcess != null){
      bool killed = _activeProcess!.kill();
      if(killed){
        setState((){
          _isConnecting = false;
          _activeProcess = null;
          logs.add("[System] Client process closed.");
        });
      }
    }
  }

  void _startClient() async {
    String inputMac = _macController.text;
    String pythonPath = getPythonPath(targetExe: exeName("blipboard_client"));
    String workingDir = getWorkingDir();
    bool isBundledExe = isBundledExePath(pythonPath);

    setState((){
      logs.add("Starting client ...");
      logs.add("Path: $pythonPath");
      logs.add("Working Dir: $workingDir");
    });
    try {
      // 检查文件是否存在
      if (!File(pythonPath).existsSync()) {
        throw Exception("Executable not found: $pythonPath");
      }

      var process = await Process.start(
        pythonPath,
        isBundledExe ? [inputMac] : ["-u","blipboard_client.py", inputMac],
        workingDirectory: workingDir,
        runInShell: false
      );
      setState((){
        _activeProcess = process;
        _isConnecting = true;
      });
      process.exitCode.then((code){
        setState((){
          _isConnecting = false;
          _activeProcess = null;
          logs.add("[System] Python process stopped (code: $code)\n");
        });
      });
      process.stdout.transform(utf8.decoder).listen((data){
        setState((){
          logs.add(data.trim());
        });
        scrollToBottom(_scrollController);
      });
      process.stderr.transform(utf8.decoder).listen((data){
        setState((){
          logs.add("Error: ${data.trim()}");
        });
      });
    } catch(e) {
      logs.add("Failed to start python script, please check path: $e");
    }
  }

  @override
  void dispose(){
    _macController.dispose();
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
        title: const Text(
          "Blipboard Client",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
        ),
        foregroundColor: Color(0xff0082fc)
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            TextField(
              controller: _macController,
              decoration: const InputDecoration(
                labelText: "Server Mac Address",
                hintText: "e.g. 00:00:00:00:00:00",
                prefixIcon: Icon(Icons.bluetooth),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:20),
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? _stopClient : _startClient,
                icon: Icon(
                  _isConnecting ? Icons.bluetooth_disabled : Icons.bluetooth_connected
                ),
                label: Text(
                  _isConnecting ?  "Disconnect" : "Connect"
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _isConnecting ? Colors.redAccent : const Color(0xFF0082FC)
                ),
              ),
            ),
            const SizedBox(height:20),
            const Text("CLIENT LOG", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height:10),
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
            // const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}