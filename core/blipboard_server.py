import argparse
import platform
import random
import signal
import socket
import pyperclip
import threading
import uuid
import transmission.transmission
import subprocess
import sys

# Disable stdout buffering for packaged executable to ensure GUI receives logs in real-time
sys.stdout.reconfigure(line_buffering=True)

# Usable RFCOMM channels per the Bluetooth spec (DLCI 1-30).
RFCOMM_CHANNEL_MIN = 1
RFCOMM_CHANNEL_MAX = 30
DEFAULT_PORT = 4

_stop_event = threading.Event()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Blipboard bluetooth clipboard server")
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help=f"RFCOMM channel to listen on ({RFCOMM_CHANNEL_MIN}-{RFCOMM_CHANNEL_MAX}, default {DEFAULT_PORT})",
    )
    parser.add_argument(
        "--random-port",
        action="store_true",
        help="listen on a randomly picked free RFCOMM channel instead of the fixed one",
    )
    return parser.parse_args()


def _request_stop(signum, frame):
    _stop_event.set()


def install_stop_handlers() -> None:
    """
    Translate SIGTERM / SIGINT into a stop flag so every loop below can
    unwind and release the Bluetooth port promptly.
    """
    for sig in (signal.SIGTERM, signal.SIGINT):
        try:
            signal.signal(sig, _request_stop)
        except (OSError, ValueError):
            pass


def get_mac() -> str:
    """
    Get MAC address for this device.
    
    :return: mac address
    :rtype: str
    """
    if platform.system()=="Windows":
        return ':'.join(['{:02X}'.format((uuid.getnode() >> elements) & 0xff) for elements in range(0,8*6,8)][::-1])
    else:
        result = subprocess.check_output(["hciconfig"])
        mac_address = ""
        for line in result.decode().split('\n'):
            if "BD Address" in line:
                mac_address = line.split()[2]
                break
        return mac_address

def handle_client_session(client_sock:socket.socket) -> None:
    """
    Communicate with a connected client.
    This function ends when the client is disconnected or a stop is requested.
    
    :param client_sock: client socket
    :type client_sock: socket.socket
    """
    client_sock.settimeout(1.0)
    while not _stop_event.is_set():
        try:
            message = transmission.transmission.recv_data(client_sock)
            if not message:
                print("[Server] Client disconnected. Waiting for connection ...")
                break
            if message["request"]=="PUSH":
                # currently this only processes plain text
                if message["dataType"]=="text":
                    new_text = message["data"]
                    pyperclip.copy(new_text)
                    print("[Server] Clipboard updated.")
            elif message["request"]=="PULL":
                print("[Server] Pull request received, pushing clipboard ...")
                content = pyperclip.paste()
                packet = transmission.transmission.pack_data(
                    request="PUSH",
                    dataType="text",
                    data=content
                )
                client_sock.sendall(packet)
                print("[Server] Push success!")
        except socket.timeout:
            continue
        except ConnectionResetError:
            print("[Server] Connection forced to reset.")
            break

def bind_random_channel(server_mac: str):
    """
    Try every RFCOMM channel in random order and return (channel, socket)
    for the first one that binds successfully, so a busy fixed channel
    (e.g. another service already on 4) no longer blocks startup.
    """
    candidates = list(range(RFCOMM_CHANNEL_MIN, RFCOMM_CHANNEL_MAX + 1))
    random.shuffle(candidates)
    last_error = None
    for channel in candidates:
        sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
        try:
            sock.bind((server_mac, channel))
            return channel, sock
        except OSError as e:
            last_error = e
            sock.close()
    raise OSError(f"No free RFCOMM channel in {RFCOMM_CHANNEL_MIN}-{RFCOMM_CHANNEL_MAX}: {last_error}")

def run_server() -> None:
    """
    Run the server: listen and connect.
    """
    install_stop_handlers()
    args = parse_args()
    port = args.port
    if not (RFCOMM_CHANNEL_MIN <= port <= RFCOMM_CHANNEL_MAX):
        print(f"[Server] Error: --port must be {RFCOMM_CHANNEL_MIN}-{RFCOMM_CHANNEL_MAX}, got {port}.")
        sys.exit(2)
    SERVER_MAC = get_mac()
    print(f"Server MAC address: {SERVER_MAC}")
    client_sock = None
    try:
        if args.random_port:
            PORT, server_sock = bind_random_channel(SERVER_MAC)
            print(f"[Server] Random port mode: bound to channel {PORT}.")
        else:
            server_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)
            server_sock.bind((SERVER_MAC,port))
            PORT = port
        # bind and listen
        server_sock.listen(1)
        server_sock.settimeout(1.0)
        print(f"[Server] Service started, listening to port {PORT} ...")
        print("[Server] Waiting for connection, enter Ctrl+C to exit.")
        while not _stop_event.is_set():
            # connect to client
            try:
                client_sock, address = server_sock.accept()
                print(f"[Server] Connected to device {address}.")
            except socket.timeout:
                continue
            # communication
            try:
                handle_client_session(client_sock)
            finally:
                client_sock.close()
                client_sock = None
        print("[Server] Stop requested, exiting ...")
    except KeyboardInterrupt:
        print("[Server] Exiting ...")
    except Exception as e:
        print(f"[Server] Error: {e}")
        sys.exit(1)
    finally:
        for sock in (client_sock, server_sock):
            if sock is not None:
                try:
                    sock.close()
                except OSError:
                    pass
        print("[Server] Server closed!")

if __name__=="__main__":
    run_server()
