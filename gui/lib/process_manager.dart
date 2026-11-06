import 'dart:async';
import 'dart:ffi';
import 'dart:io';

const int _jobObjectExtendedLimitInformation = 9;
const int _jobObjectLimitKillOnJobClose = 0x2000;
const int _processTerminate = 0x0001;
const int _processSetQuota = 0x0100;
const int _heapZeroMemory = 0x08;

final Set<Process> _liveProcesses = {};

Pointer<Void> _killOnCloseJob = nullptr;
bool _jobInitialized = false;

Future<Process> startManagedProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
  _liveProcesses.add(process);
  process.exitCode.whenComplete(() => _liveProcesses.remove(process));
  if (Platform.isWindows) {
    _addToKillOnCloseJob(process.pid);
  }
  return process;
}

Future<void> stopProcessTree(
  Process process, {
  Duration grace = const Duration(seconds: 3),
}) async {
  _liveProcesses.remove(process);
  try {
    if (Platform.isWindows) {
      await _runIgnoringErrors('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
    } else {
      await _runIgnoringErrors('pkill', ['-TERM', '-P', '${process.pid}']);
      process.kill(ProcessSignal.sigterm);
    }
    await process.exitCode.timeout(grace);
    return;
  } catch (_) {}
  try {
    if (Platform.isWindows) {
      await _runIgnoringErrors('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
    } else {
      await _runIgnoringErrors('pkill', ['-KILL', '-P', '${process.pid}']);
      process.kill(ProcessSignal.sigkill);
    }
    await process.exitCode.timeout(const Duration(seconds: 5));
  } catch (_) {}
}

void killAllSync() {
  final processes = List<Process>.of(_liveProcesses);
  _liveProcesses.clear();
  for (final process in processes) {
    try {
      if (Platform.isWindows) {
        Process.runSync('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
      } else {
        try {
          Process.runSync('pkill', ['-KILL', '-P', '${process.pid}']);
        } catch (_) {}
        process.kill(ProcessSignal.sigkill);
      }
    } catch (_) {}
  }
}

Future<void> _runIgnoringErrors(String executable, List<String> arguments) async {
  try {
    await Process.run(executable, arguments);
  } catch (_) {}
}

final class _IoCounters extends Struct {
  @Uint64()
  external int readOperationCount;
  @Uint64()
  external int writeOperationCount;
  @Uint64()
  external int otherOperationCount;
  @Uint64()
  external int readTransferCount;
  @Uint64()
  external int writeTransferCount;
  @Uint64()
  external int otherTransferCount;
}

final class _JobObjectBasicLimitInformation extends Struct {
  @Int64()
  external int perProcessUserTimeLimit;
  @Int64()
  external int perJobUserTimeLimit;
  @Uint32()
  external int limitFlags;
  @IntPtr()
  external int minimumWorkingSetSize;
  @IntPtr()
  external int maximumWorkingSetSize;
  @Uint32()
  external int activeProcessLimit;
  @IntPtr()
  external int affinity;
  @Uint32()
  external int priorityClass;
  @Uint32()
  external int schedulingClass;
}

final class _JobObjectExtendedLimitInformation extends Struct {
  external _JobObjectBasicLimitInformation basicLimitInformation;
  external _IoCounters ioInfo;
  @IntPtr()
  external int processMemoryLimit;
  @IntPtr()
  external int jobMemoryLimit;
  @IntPtr()
  external int peakProcessMemoryUsed;
  @IntPtr()
  external int peakJobMemoryUsed;
}

typedef _CreateJobObjectNative = Pointer<Void> Function(Pointer<Void>, Pointer<Void>);
typedef _CreateJobObject = Pointer<Void> Function(Pointer<Void>, Pointer<Void>);
typedef _SetInformationJobObjectNative = Int32 Function(
  Pointer<Void>,
  Uint32,
  Pointer<_JobObjectExtendedLimitInformation>,
  Uint32,
);
typedef _SetInformationJobObject = int Function(
  Pointer<Void>,
  int,
  Pointer<_JobObjectExtendedLimitInformation>,
  int,
);
typedef _OpenProcessNative = Pointer<Void> Function(Uint32, Int32, Uint32);
typedef _OpenProcess = Pointer<Void> Function(int, int, int);
typedef _AssignProcessToJobObjectNative = Int32 Function(Pointer<Void>, Pointer<Void>);
typedef _AssignProcessToJobObject = int Function(Pointer<Void>, Pointer<Void>);
typedef _GetProcessHeapNative = Pointer<Void> Function();
typedef _GetProcessHeap = Pointer<Void> Function();
typedef _HeapAllocNative = Pointer<Void> Function(Pointer<Void>, Uint32, Size);
typedef _HeapAlloc = Pointer<Void> Function(Pointer<Void>, int, int);
typedef _HeapFreeNative = Int32 Function(Pointer<Void>, Uint32, Pointer<Void>);
typedef _HeapFree = int Function(Pointer<Void>, int, Pointer<Void>);
typedef _CloseHandleNative = Int32 Function(Pointer<Void>);
typedef _CloseHandle = int Function(Pointer<Void>);

void _addToKillOnCloseJob(int pid) {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  if (!_jobInitialized) {
    _jobInitialized = true;
    _killOnCloseJob = _createKillOnCloseJob(kernel32);
  }
  final job = _killOnCloseJob;
  if (job == nullptr) return;
  final openProcess = kernel32.lookupFunction<_OpenProcessNative, _OpenProcess>('OpenProcess');
  final handle = openProcess(_processSetQuota | _processTerminate, 0, pid);
  if (handle == nullptr) return;
  try {
    final assign = kernel32
        .lookupFunction<_AssignProcessToJobObjectNative, _AssignProcessToJobObject>(
      'AssignProcessToJobObject',
    );
    assign(job, handle);
  } finally {
    kernel32.lookupFunction<_CloseHandleNative, _CloseHandle>('CloseHandle')(handle);
  }
}

Pointer<Void> _createKillOnCloseJob(DynamicLibrary kernel32) {
  final createJobObject = kernel32.lookupFunction<_CreateJobObjectNative, _CreateJobObject>(
    'CreateJobObjectW',
  );
  final closeHandle = kernel32.lookupFunction<_CloseHandleNative, _CloseHandle>('CloseHandle');
  final job = createJobObject(nullptr, nullptr);
  if (job == nullptr) return nullptr;
  final getProcessHeap = kernel32.lookupFunction<_GetProcessHeapNative, _GetProcessHeap>(
    'GetProcessHeap',
  );
  final heapAlloc = kernel32.lookupFunction<_HeapAllocNative, _HeapAlloc>('HeapAlloc');
  final heapFree = kernel32.lookupFunction<_HeapFreeNative, _HeapFree>('HeapFree');
  final heap = getProcessHeap();
  final infoSize = sizeOf<_JobObjectExtendedLimitInformation>();
  final info = heapAlloc(heap, _heapZeroMemory, infoSize);
  if (info == nullptr) {
    closeHandle(job);
    return nullptr;
  }
  try {
    final infoView = info.cast<_JobObjectExtendedLimitInformation>();
    infoView.ref.basicLimitInformation.limitFlags = _jobObjectLimitKillOnJobClose;
    final setInformation = kernel32
        .lookupFunction<_SetInformationJobObjectNative, _SetInformationJobObject>(
      'SetInformationJobObject',
    );
    if (setInformation(job, _jobObjectExtendedLimitInformation, infoView, infoSize) != 0) {
      return job;
    }
  } finally {
    heapFree(heap, 0, info);
  }
  closeHandle(job);
  return nullptr;
}
