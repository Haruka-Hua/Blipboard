import socket

target_mac = "C8:6E:08:E2:5C:E7" 
port = 4

# create client socket
client_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)

print(f"--- [Client] Trying to connect to {target_mac}")

try:
    # connect to server
    client_sock.connect((target_mac,port))
    print("--- [Client] Connect succcess! ---")

    # receive data
    while True:
        try:
            client_sock.send(input().encode('utf-8'))
            print("--- [Client] Message has been sent to server! ---")
        except KeyboardInterrupt:
            break
except Exception as e:
    print((f"--- [Client] Failure: {e} ---"))
finally:
    client_sock.close()