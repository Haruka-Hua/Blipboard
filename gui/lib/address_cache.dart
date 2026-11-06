import "dart:io";

/// The last server the client connected to.
class CachedServer {
  final String mac;
  final int port;

  const CachedServer(this.mac, this.port);
}

/// Persists the last server address the client connected to, so the user can
/// reconnect without re-typing it. Storage is a two-line text file ("MAC" then
/// "port") under the platform's per-user config/app-data directory. Every
/// failure is swallowed: the cache is a convenience and must never break
/// connecting.
class AddressCache {
  static const String _fileName = "last_server.txt";

  /// Location of the cache file, or null if no per-user directory can be
  /// resolved (then the feature silently disables itself).
  static File? cacheFile() {
    if (Platform.isWindows) {
      final appData = Platform.environment["APPDATA"];
      if (appData == null || appData.isEmpty) return null;
      return File("$appData\\Blipboard\\$_fileName");
    }
    final home = Platform.environment["HOME"];
    if (home == null || home.isEmpty) return null;
    if (Platform.isMacOS) {
      return File("$home/Library/Application Support/Blipboard/$_fileName");
    }
    // Linux and other POSIX systems follow XDG.
    final xdg = Platform.environment["XDG_CONFIG_HOME"];
    final configRoot = (xdg == null || xdg.isEmpty) ? "$home/.config" : xdg;
    return File("$configRoot/blipboard/$_fileName");
  }

  /// Returns the last saved server, or null when missing/empty/unreadable.
  /// The port line is optional (older caches stored only the MAC) and falls
  /// back to 4 when absent or unparsable. MAC format validation is up to the
  /// caller.
  static Future<CachedServer?> loadLastServer() async {
    try {
      final file = cacheFile();
      if (file == null) return null;
      if (!await file.exists()) return null;
      final lines = (await file.readAsString()).split("\n");
      final mac = lines.isEmpty ? "" : lines[0].trim();
      if (mac.isEmpty) return null;
      final port = lines.length > 1 ? int.tryParse(lines[1].trim()) : null;
      return CachedServer(mac, port ?? 4);
    } catch (_) {
      return null;
    }
  }

  /// Saves [mac] and [port] as the last used server.
  static Future<void> saveLastServer(String mac, int port) async {
    try {
      final file = cacheFile();
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsString("$mac\n$port\n");
    } catch (_) {}
  }
}
