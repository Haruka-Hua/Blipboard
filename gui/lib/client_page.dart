import "package:flutter/material.dart";
import "dart:io";
import "dart:convert";
import "address_cache.dart";
import "process_manager.dart";
import "utils.dart";

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  static final RegExp _macPattern = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$');
  static const int _defaultPort = 4;
  static const int _maxRfcommChannel = 30;

  final TextEditingController _macController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  List<String> logs = [];
  Process? _activeProcess;
  bool _isConnecting = false;
  bool _isStarting = false;
  bool _isStopping = false;
  String? _lastServerMac;
  final ScrollController _scrollController = ScrollController();

  bool get _isBusy => _isStarting || _isStopping;

  /// Commands can only be sent to a running client process.
  bool get _canSendCommands => _isConnecting && !_isBusy;

  @override
  void initState(){
    super.initState();
    _loadCachedAddress();
  }

  Future<void> _loadCachedAddress() async {
    final cached = await AddressCache.loadLastServer();
    if (cached == null || !_macPattern.hasMatch(cached.mac)) return;
    if (!mounted) return;
    setState((){
      _lastServerMac = cached.mac;
      if (_portController.text.isEmpty){
        _portController.text = "${cached.port}";
      }
    });
  }

  Future<void> _stopClient() async {
    final process = _activeProcess;
    if (process == null || _isStopping) return;
    setState((){
      _isStopping = true;
      logs.add("[System] Stopping client ...");
    });
    await stopProcessTree(process);
    if (!mounted) return;
    setState((){
      _isStopping = false;
      _isConnecting = false;
      _activeProcess = null;
      logs.add("[System] Client process closed.");
    });
  }

  /// Send a PUSH/PULL command to the running client process via stdin.
  Future<void> _sendCommand(String command) async {
    final process = _activeProcess;
    if (process == null || !_canSendCommands) return;
    try {
      process.stdin.writeln(command);
      await process.stdin.flush();
    } catch (e) {
      if (!mounted) return;
      setState((){
        logs.add("[System] Failed to send $command command: $e");
      });
    }
  }

  Future<void> _startClient() async {
    if (_isConnecting || _isBusy) return;
    final typedMac = _macController.text.trim();
    final String macToUse;
    if (typedMac.isEmpty) {
      // Empty input: fall back to the last connected address, if any.
      final cached = _lastServerMac;
      if (cached == null) {
        setState((){
          logs.add("No server MAC address entered and no previous address cached. Please enter one (e.g. 00:1A:2B:3C:4D:5E).");
        });
        return;
      }
      macToUse = cached;
      setState((){
        logs.add("[System] No address entered, reusing last connected server: $macToUse");
      });
    } else if (!_macPattern.hasMatch(typedMac)) {
      setState((){
        logs.add("Please enter a valid server MAC address (e.g. 00:1A:2B:3C:4D:5E).");
      });
      return;
    } else {
      macToUse = typedMac;
    }
    final portText = _portController.text.trim();
    final int portToUse;
    if (portText.isEmpty) {
      portToUse = _defaultPort;
    } else {
      final parsed = int.tryParse(portText);
      if (parsed == null || parsed < 1 || parsed > _maxRfcommChannel) {
        setState((){
          logs.add("Server port must be an RFCOMM channel between 1 and $_maxRfcommChannel (leave empty for $_defaultPort).");
        });
        return;
      }
      portToUse = parsed;
    }
    String pythonPath = getPythonPath(targetExe: exeName("blipboard_client"));
    String workingDir = getWorkingDir();
    bool isBundledExe = isBundledExePath(pythonPath);

    setState((){
      _isStarting = true;
      logs.add("Starting client ...");
      logs.add("Path: $pythonPath");
      logs.add("Working Dir: $workingDir");
    });
    try {
      // 检查文件是否存在
      if (!File(pythonPath).existsSync()) {
        throw Exception("Executable not found: $pythonPath");
      }

      final portArgs = ["--port", "$portToUse"];
      final process = await startManagedProcess(
        pythonPath,
        isBundledExe
            ? [macToUse, ...portArgs]
            : ["-u","blipboard_client.py", macToUse, ...portArgs],
        workingDirectory: workingDir,
      );
      if (!mounted){
        await stopProcessTree(process);
        return;
      }
      setState((){
        _isStarting = false;
        _activeProcess = process;
        _isConnecting = true;
        _lastServerMac = macToUse;
      });
      await AddressCache.saveLastServer(macToUse, portToUse);
      process.exitCode.then((code){
        if (!mounted) return;
        setState((){
          if (_activeProcess == process){
            _activeProcess = null;
            _isConnecting = false;
            _isStopping = false;
          }
          logs.add("[System] Python process stopped (code: $code)");
        });
      });
      process.stdout.transform(utf8.decoder).listen((data){
        if (!mounted) return;
        setState((){
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
    } catch(e) {
      if (!mounted) return;
      setState((){
        _isStarting = false;
        logs.add("Failed to start python script, please check path: $e");
      });
    }
  }

  @override
  void dispose(){
    _macController.dispose();
    _portController.dispose();
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _macController,
                    decoration: InputDecoration(
                      labelText: "Server Mac Address",
                      hintText: "e.g. 00:00:00:00:00:00",
                      helperText: _lastServerMac != null
                          ? "Leave empty to reconnect to $_lastServerMac"
                          : null,
                      prefixIcon: const Icon(Icons.bluetooth),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Port",
                      hintText: "Default 4",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height:20),
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isBusy ? null : (_isConnecting ? _stopClient : _startClient),
                icon: Icon(
                  _isConnecting ? Icons.bluetooth_disabled : Icons.bluetooth_connected
                ),
                label: Text(
                  _isStopping ? "Stopping ..."
                  : _isStarting ? "Starting ..."
                  : _isConnecting ? "Disconnect" : "Connect"
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _isConnecting ? Colors.redAccent : const Color(0xFF0082FC)
                ),
              ),
            ),
            const SizedBox(height:20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _canSendCommands ? () => _sendCommand("PUSH") : null,
                  icon: const Icon(Icons.north),
                  label: const Text("Push"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0082FC),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _canSendCommands ? () => _sendCommand("PULL") : null,
                  icon: const Icon(Icons.south),
                  label: const Text("Pull"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0082FC),
                  ),
                ),
              ],
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
