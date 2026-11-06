import argparse
import json
import os
import re
import signal
import socket
import pyperclip
import threading
import keyboard
import transmission.transmission
import sys

# Disable stdout buffering for packaged executable to ensure GUI receives logs in real-time
sys.stdout.reconfigure(line_buffering=True)

RECONNECT_DELAY = 3.0
MAC_PATTERN = re.compile(r"^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$")

# Usable RFCOMM channels per the Bluetooth spec (DLCI 1-30).
RFCOMM_CHANNEL_MIN = 1
RFCOMM_CHANNEL_MAX = 30
DEFAULT_PORT = 4

# Hotkey bindings live in config.json next to the script/executable so users
# can edit them without touching the code. A default file is created on
# first run; invalid entries fall back to these defaults.
CONFIG_FILE_NAME = "config.json"
DEFAULT_HOTKEYS = {"push": "ctrl+alt+c", "pull": "ctrl+alt+v"}
HOTKEYS = dict(DEFAULT_HOTKEYS)

_stop_event = threading.Event()
# GUI buttons trigger push/pull by writing PUSH/PULL lines to our stdin; the
# reader thread below only sets these flags so all socket work stays on the
# main loop's thread.
_push_event = threading.Event()
_pull_event = threading.Event()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Blipboard bluetooth clipboard client")
    parser.add_argument("mac", nargs="?", default=None, help="server MAC address")
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help=f"RFCOMM channel of the server ({RFCOMM_CHANNEL_MIN}-{RFCOMM_CHANNEL_MAX}, default {DEFAULT_PORT})",
    )
    return parser.parse_args()


def app_dir() -> str:
    """Directory of the script (dev mode) or the packaged executable."""
    if getattr(sys, "frozen", False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))


def _write_default_config(path: str) -> None:
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump({"hotkeys": DEFAULT_HOTKEYS}, f, indent=2)
            f.write("\n")
    except OSError:
        pass


def load_hotkeys() -> dict:
    """
    Load hotkey bindings from config.json, creating the file with defaults
    when missing. Anything unreadable or unparsable falls back to defaults.
    """
    hotkeys = dict(DEFAULT_HOTKEYS)
    path = os.path.join(app_dir(), CONFIG_FILE_NAME)
    try:
        with open(path, "r", encoding="utf-8") as f:
            configured = json.load(f).get("hotkeys", {})
        for action in hotkeys:
            value = configured.get(action)
            if isinstance(value, str) and value.strip():
                hotkeys[action] = value.strip()
    except FileNotFoundError:
        _write_default_config(path)
    except (OSError, ValueError) as e:
        print(f"[Client] Warning: could not read {CONFIG_FILE_NAME} ({e}), using default hotkeys.")
    for action, combo in hotkeys.items():
        try:
            keyboard.parse_hotkey(combo)
        except Exception:
            print(f"[Client] Warning: invalid hotkey '{combo}' for {action}, falling back to '{DEFAULT_HOTKEYS[action]}'.")
            hotkeys[action] = DEFAULT_HOTKEYS[action]
    return hotkeys


def _stdin_command_loop() -> None:
    """
    Read PUSH/PULL commands from stdin (one per line) so the GUI buttons can
    trigger the same actions as the hotkeys. Exits silently on EOF.
    """
    while not _stop_event.is_set():
        try:
            line = sys.stdin.readline()
        except (OSError, ValueError):
            return
        if not line:
            return  # stdin closed (e.g. GUI exited): nothing more to read
        cmd = line.strip().upper()
        if cmd == "PUSH":
            _push_event.set()
        elif cmd == "PULL":
            _pull_event.set()


def _request_stop(signum, frame):
    _stop_event.set()


def install_stop_handlers() -> None:
    """
    Translate SIGTERM / SIGINT into a stop flag so every loop below can
    unwind and release the connection promptly.
    """
    for sig in (signal.SIGTERM, signal.SIGINT):
        try:
            signal.signal(sig, _request_stop)
        except (OSError, ValueError):
            pass


def wait_or_stop(seconds: float) -> None:
    """
    Sleep for the given duration, but return immediately once a stop is
    requested instead of blocking the shutdown.
    """
    _stop_event.wait(seconds)


def do_push(client_sock:socket.socket) -> None:
    """Send the local clipboard content to the server."""
    content = pyperclip.paste()
    if not content:
        print("[Client] Nothing to push: local clipboard is empty.")
        return
    print("[Client] Pushing clipboard content ...")
    packet = transmission.transmission.pack_data(
        request="PUSH",
        data=content,
        dataType="text"
    )
    client_sock.sendall(packet)
    print("[Client] Push success!")


def do_pull(client_sock:socket.socket) -> bool:
    """
    Fetch the server clipboard into the local clipboard.
    Returns False when a stop was requested while waiting for the reply.
    """
    print("[Client] Sending pull request ...")
    packet = transmission.transmission.pack_data(request="PULL")
    client_sock.sendall(packet)
    message = None
    while not _stop_event.is_set():
        try:
            message = transmission.transmission.recv_data(client_sock)
            break
        except socket.timeout:
            continue
    if message is None:
        return False
    if message["request"]=="PUSH":
        pyperclip.copy(message["data"])
        print("[Client] Pull success! Clipboard updated.")
    return True


def handle_request(client_sock:socket.socket) -> None:
    """
    Send request and synchronize the clipboard. Triggers are the configured
    hotkeys and PUSH/PULL commands arriving on stdin (GUI buttons).

    :param client_sock: client socket
    :type client_sock: socket.socket
    """
    client_sock.settimeout(1.0)
    print("--- Blipboard Guide ---")
    print(f"Push: {HOTKEYS['push']} (or the GUI Push button).")
    print(f"Pull: {HOTKEYS['pull']} (or the GUI Pull button).")
    print(f"Edit {CONFIG_FILE_NAME} to customize the hotkeys. Ctrl + C at terminal: Exit.")
    while not _stop_event.is_set():
        if _push_event.is_set():
            _push_event.clear()
            do_push(client_sock)
            wait_or_stop(0.5)
        elif _pull_event.is_set():
            _pull_event.clear()
            if not do_pull(client_sock):
                return
            wait_or_stop(0.5)
        elif keyboard.is_pressed(HOTKEYS["push"]):
            do_push(client_sock)
            wait_or_stop(0.5)
        elif keyboard.is_pressed(HOTKEYS["pull"]):
            if not do_pull(client_sock):
                return
            wait_or_stop(0.5)
        else:
            wait_or_stop(0.01)

def get_mac(cli_mac) -> str:
    if cli_mac and cli_mac.strip():
        return cli_mac.strip()
    if sys.stdin is not None and sys.stdin.isatty():
        # On Windows the NUL device also reports isatty() as True, so an
        # EOF here must fall through to the error below instead of crashing.
        try:
            mac = input("Please enter the target server's MAC address: ").strip()
        except (EOFError, OSError):
            mac = ""
        if mac:
            return mac
    print("[Client] Error: no server MAC address was given.")
    sys.exit(2)

def run_client() -> None:
    """
    Run the client: connect and request.
    """
    global HOTKEYS
    install_stop_handlers()
    args = parse_args()
    PORT = args.port
    if not (RFCOMM_CHANNEL_MIN <= PORT <= RFCOMM_CHANNEL_MAX):
        print(f"[Client] Error: --port must be {RFCOMM_CHANNEL_MIN}-{RFCOMM_CHANNEL_MAX}, got {PORT}.")
        sys.exit(2)
    HOTKEYS = load_hotkeys()
    print(f"[Client] Hotkeys: push={HOTKEYS['push']}, pull={HOTKEYS['pull']} (edit {CONFIG_FILE_NAME} to customize).")
    SERVER_MAC = get_mac(args.mac)
    SERVER_MAC = SERVER_MAC.replace('-',':').upper()
    if not MAC_PATTERN.match(SERVER_MAC):
        print(f"[Client] Error: '{SERVER_MAC}' is not a valid MAC address.")
        sys.exit(2)
    print(f"[Client] Client started. Target server: {SERVER_MAC}, port: {PORT}.")
    threading.Thread(target=_stdin_command_loop, daemon=True).start()
    client_sock = None
    try:
        while not _stop_event.is_set():
            client_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)
            try:
                client_sock.settimeout(2.0)
                print("[Client] Trying to connect to server ...")
                client_sock.connect((SERVER_MAC,PORT))
                print("[Client] Connected to server!")
                # Drop commands queued while we were disconnected.
                _push_event.clear()
                _pull_event.clear()
                handle_request(client_sock)
            except socket.timeout:
                print(f"[Client] Unable to connect to server. Trying to reconnect after {RECONNECT_DELAY} seconds ...")
                wait_or_stop(RECONNECT_DELAY)
            except OSError as e:
                print(f"[Client] Error: {e} \nTrying to reconnect in {RECONNECT_DELAY} seconds ...")
                wait_or_stop(RECONNECT_DELAY)
            finally:
                if client_sock is not None:
                    try:
                        client_sock.close()
                    except OSError:
                        pass
                    client_sock = None
        print("[Client] Stop requested, exiting ...")
    except KeyboardInterrupt:
        print("[Client] Keyboard Interrupt.")
    finally:
        if client_sock is not None:
            try:
                client_sock.close()
            except OSError:
                pass
        print("[Client] Client closed.")

if __name__ == "__main__":
    run_client()
