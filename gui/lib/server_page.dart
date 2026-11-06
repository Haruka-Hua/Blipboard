import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "dart:io";
import "dart:convert";
import "process_manager.dart";
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
  bool _isStarting = false;
  bool _isStopping = false;
  bool _useRandomPort = false;
  String _localMac = "Unknown";
  final ScrollController _scrollController = ScrollController();

  bool get _isBusy => _isStarting || _isStopping;

  Future<void> _stopServer() async {
    final process = _activeProcess;
    if (process == null || _isStopping) return;
    setState((){
      _isStopping = true;
      logs.add("[System] Stopping server ...");
    });
    await stopProcessTree(process);
    if (!mounted) return;
    setState((){
      _isStopping = false;
      _isServiceRunning = false;
      _activeProcess = null;
      logs.add("[System] Server process stopped.");
    });
  }

  Future<void> _startServer() async {
    if (_isServiceRunning || _isBusy) return;
    String pythonPath = getPythonPath(targetExe: exeName("blipboard_server"));
    String workingDir = getWorkingDir();
    bool isBundledExe = isBundledExePath(pythonPath);

    setState((){
      _isStarting = true;
      logs.add("Starting server ...");
      logs.add("Path: $pythonPath");
      logs.add("Working Dir: $workingDir"); // Debug info
    });

    try{
      // 检查文件是否存在
      if (!File(pythonPath).existsSync()) {
        throw Exception("Executable not found: $pythonPath");
      }

      final randomPortArgs = _useRandomPort ? ["--random-port"] : <String>[];
      final process = await startManagedProcess(
        pythonPath,
        isBundledExe
            ? randomPortArgs
            : ["-u", "blipboard_server.py", ...randomPortArgs],
        workingDirectory: workingDir,
      );
      if (!mounted){
        await stopProcessTree(process);
        return;
      }
      setState((){
        _isStarting = false;
        _activeProcess = process;
        _isServiceRunning = true;
      });
      process.exitCode.then((code){
        if (!mounted) return;
        setState((){
          if (_activeProcess == process){
            _activeProcess = null;
            _isServiceRunning = false;
            _isStopping = false;
          }
          logs.add("[System] Python process stopped (code: $code)");
        });
      });
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((data){
        if (!mounted) return;
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
        if (!mounted) return;
        setState((){
          logs.add("Error: ${data.trim()}");
        });
      });
    } catch(e){
      if (!mounted) return;
      setState((){
        _isStarting = false;
        logs.add("Failed to start python script, please check path: $e");
      });
    }
  }

  @override
  void dispose(){
    _scrollController.dispose();
    final process = _activeProcess;
    if (process != null){
      stopProcessTree(process);
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Use a random available port",
                      style: TextStyle(fontSize: 15),
                    ),
                    subtitle: const Text(
                      "Avoids conflicts when channel 4 is taken. The client must connect to the port shown in the log.",
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _useRandomPort,
                    onChanged: (_isBusy || _isServiceRunning) ? null : (value){
                      setState((){
                        _useRandomPort = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : (_isServiceRunning ? _stopServer : _startServer),
                      icon: Icon(_isServiceRunning ? Icons.stop : Icons.start),
                      label: Text(
                        _isStopping ? "Stopping ..."
                        : _isStarting ? "Starting ..."
                        : _isServiceRunning ? "Stop Server" : "Start Server"
                      ),
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
