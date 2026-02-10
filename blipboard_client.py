import socket
import pyperclip
import time

target_mac = "C8:6E:08:E2:5C:E7" 
port = 4

client_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)
print(f"[Client] Trying to connect to {target_mac}")

try:
    # connect server
    print("[Client] Connecting...")
    client_sock.connect((target_mac, port))
    print("[Client] Connected successfully!")
    # get clipboard content
    last_content = pyperclip.paste()
    while True:
        try:
            current_content = pyperclip.paste()
            if current_content != last_content:
                if current_content:
                    print("[Client] Syncing clipboard ...")
                    client_sock.send(current_content.encode('utf-8'))
                last_content = current_content
            time.sleep(0.5)
        except KeyboardInterrupt:
            print("[Client] User required to exit.")
            break
except Exception as e:
    print(f"[Client] Error: {e}")
finally:
    client_sock.close()
    print("[Client] Blipboard client closed.")