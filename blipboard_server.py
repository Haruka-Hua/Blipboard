import socket
import pyperclip

server_mac = "C8:6E:08:E2:5C:E7" 
port = 4

# create socket
server_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)

try:
    # bind and listen
    server_sock.bind((server_mac,port))
    server_sock.listen(1)
    print("[Server] Waiting for connection, enter Ctrl+C to exit.")
    # connect to client
    server_sock.settimeout(1.0)

    client_connected = False
    while not client_connected:
        try:
            client_sock, client_address = server_sock.accept()
            print(f"[Server] Connected to: {client_address}.")
            client_connected = True
        except socket.timeout:
            continue
    # receive data
    client_sock.settimeout(1.0)
    while True:
        try:
            data = client_sock.recv(4096)
            if not data:
                print("[Server] Client disconnected.")
                break

            new_text = data.decode('utf-8')
            pyperclip.copy(new_text)
            print("[Server] Clipboard updated.")
        except socket.timeout:
            continue
except KeyboardInterrupt:
    print("[Server] Exiting ...")
except Exception as e:
    print(f"[Server] Error: {e}")
finally:
    if "client_sock" in locals():
        client_sock.close()
    server_sock.close()
    print("[Server] Server closed!")