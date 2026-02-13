import socket
import pyperclip
import uuid
import transmission.transmission

server_mac = ':'.join(['{:02X}'.format((uuid.getnode() >> elements) & 0xff) for elements in range(0,8*6,8)][::-1])
print(f"Server MAC address: {server_mac}")
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
            message = transmission.transmission.recv_data(client_sock)
            if not message:
                print("[Server] Client disconnected.")
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
        
except KeyboardInterrupt:
    print("[Server] Exiting ...")
except Exception as e:
    print(f"[Server] Error: {e}")
finally:
    if "client_sock" in locals():
        client_sock.close()
    server_sock.close()
    print("[Server] Server closed!")