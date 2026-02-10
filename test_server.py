import socket

server_mac = "C8:6E:08:E2:5C:E7" 
port = 4

# create socket
server_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)

# bind and listen
server_sock.bind((server_mac,port))
server_sock.listen(5)
print("--- [Server] Waiting for connection, please start Client ---")

# accept connetcion
client_sock, client_address = server_sock.accept()
print(f"--- [Server] Connected! Found Client: {client_address} ---")

# receive data
while True:
    try:
        data = client_sock.recv(1024)
        if not data:
            print("Disconnected!")
            break
        print(f"--- [Server] Received message: {data.decode(encoding='utf-8')} ---")
    except KeyboardInterrupt:
        break
    except Exception as e:
        print(f"--- [Server] Failure: {e} ---")
        break

client_sock.close()
server_sock.close()