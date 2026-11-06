import 'dart:io';
import 'package:gui/address_cache.dart';
import 'package:gui/process_manager.dart';

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'tree' : args[0];  if (mode == 'tree') {
    final process = await startManagedProcess(
      'cmd',
      ['/c', 'ping -n 60 127.0.0.1'],
      workingDirectory: Directory.current.path,
    );
    stdout.writeln('started pid=${process.pid}');
    await Future.delayed(const Duration(milliseconds: 800));
    final sw = Stopwatch()..start();
    await stopProcessTree(process);
    sw.stop();
    final code = await process.exitCode;
    final ping = Process.runSync('tasklist', ['/FI', 'IMAGENAME eq PING.EXE']).stdout as String;
    stdout.writeln('exitCode=$code elapsedMs=${sw.elapsedMilliseconds} pingStillAlive=${ping.toLowerCase().contains('ping.exe')}');
  } else if (mode == 'job') {
    final process = await startManagedProcess(
      'ping',
      ['-n', '60', '127.0.0.1'],
      workingDirectory: Directory.current.path,
    );
    stdout.writeln('spawned pid=${process.pid}, host exits now without killing');
    await stdout.flush();
    // exit() terminates the VM right away; the OS then closes the job handle
    // and KILL_ON_JOB_CLOSE must take the child down with it. (Returning from
    // main() would NOT exit here: the pending exitCode listener keeps the VM
    // alive until the child exits, which would make this test meaningless.)
    exit(0);
  } else if (mode == 'server') {
    // Mimic the GUI lifecycle with the real Python server: Start -> Stop ->
    // immediately Start again -> Stop. Verifies the port is released before
    // the restart, which was the original user complaint.
    final repoRoot = Directory.current.parent.path;
    final python = '$repoRoot\\core\\.venv\\Scripts\\python.exe';
    var round = 0;
    Process? process;
    while (round < 2) {
      round++;
      process = await startManagedProcess(
        python,
        ['-u', 'blipboard_server.py'],
        workingDirectory: '$repoRoot\\core',
      );
      final lines = <String>[];
      final sub = process.stdout
          .transform(const SystemEncoding().decoder)
          .listen(lines.add);
      await Future.delayed(const Duration(seconds: 3));
      final sw = Stopwatch()..start();
      await stopProcessTree(process);
      sw.stop();
      await sub.cancel();
      stdout.writeln('round $round: stopped in ${sw.elapsedMilliseconds}ms, '
          'exit=${await process.exitCode}, log=${lines.join(' | ')}');
    }
  } else if (mode == 'cache') {
    // Round-trip the address cache, then delete the file so the test leaves
    // no fake address behind for the real app to pick up.
    const mac = 'AA:BB:CC:DD:EE:FF';
    const port = 7;
    await AddressCache.saveLastServer(mac, port);
    final loaded = await AddressCache.loadLastServer();
    stdout.writeln('cacheFile=${AddressCache.cacheFile()?.path}');
    stdout.writeln('roundtrip=${loaded?.mac == mac && loaded?.port == port} '
        '(loaded=${loaded?.mac}:${loaded?.port})');
    final file = AddressCache.cacheFile();
    if (file != null && await file.exists() && (await file.readAsString()).trim() == '$mac\n$port') {
      await file.delete();
      stdout.writeln('cleanup=deleted');
    }
  }
}
