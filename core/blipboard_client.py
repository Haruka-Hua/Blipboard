import socket
import pyperclip
import time
import keyboard
import transmission.transmission
import sys

RECONNECT_DELAY = 3.0

def handle_request(client_sock:socket.socket) -> None:
    """
    Send request and synchronize the clipboard.
    
    :param client_sock: client socket
    :type client_sock: socket.socket
    """
    client_sock.settimeout(1.0)
    print("--- Blipboard Guide ---")
    print("Ctrl + Alt + C : Push local clipboard content to server.")
    print("Ctrl + Alt + V : Pull server clipboard content to local.")
    print("Ctrl + C at terminal: Exit.")
    while True:
        if keyboard.is_pressed("ctrl+alt+c"):
            # push req
            content = pyperclip.paste()
            if content:
                print("[Client] Pushing clipboard content ...")
                packet = transmission.transmission.pack_data(
                    request="PUSH",
                    data=content,
                    dataType="text"
                )
                client_sock.sendall(packet)
                print("[Client] Push success!")
                time.sleep(0.5)
        elif keyboard.is_pressed("ctrl+alt+v"):
            # pull req
            print("[Client] Sending pull request ...")
            packet = transmission.transmission.pack_data(request="PULL")
            client_sock.sendall(packet)
            while True:
                try:
                    message = transmission.transmission.recv_data(client_sock)
                    break
                except socket.timeout:
                    continue
            if message is None:
                return
            elif message["request"]=="PUSH":
                pyperclip.copy(message["data"])
                print("[Client] Pull success! Clipboard updated.")
            time.sleep(0.5)
        time.sleep(0.01)

def get_mac():
    if len(sys.argv) > 1:
        return sys.argv[1]
    else:
        return input("Please enter the target server's MAC address: ")

def run_client() -> None:
    """
    Run the client: connect and request.
    """

    SERVER_MAC = get_mac()
    SERVER_MAC = SERVER_MAC.replace('-',':')
    PORT = 4
    print(f"[Client] Client started. Target server: {SERVER_MAC}, port: {PORT}.")
    try:
        while True:
            client_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)
            try:
                client_sock.settimeout(2.0)
                print("[Client] Trying to connect to server ...")
                client_sock.connect((SERVER_MAC,PORT))
                print("[Client] Connected to server!")
                handle_request(client_sock)
            except socket.timeout:
                print(f"[Client] Unable to connect to server. Trying to reconnect after {RECONNECT_DELAY} seconds ...")
                time.sleep(RECONNECT_DELAY)
                continue
            except Exception as e:
                print(f"[Client] Error: {e} \nTrying to reconnect in {RECONNECT_DELAY} seconds ...")
                time.sleep(RECONNECT_DELAY)
                continue
            finally:
                client_sock.close()
                print("[Client] Releasing resources ...")
    except KeyboardInterrupt:
            print("[Client] Keyboard Interrupt.")
    print("[Client] Exting ...")
    print("[Client] Client closed.")

if __name__ == "__main__":
    run_client()