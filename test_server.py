import socket

# 1. 创建蓝牙 Socket (RFCOMM)
# 只要是 Python 3.9+ 且是 Windows，socket 就自带这个功能
server_sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)

# 2. 绑定并监听
# 这里的 "" 代表监听本机所有蓝牙适配器，1 是频道
server_sock.bind(("C8:6E:08:E2:5C:E7", 4))
server_sock.listen(4)

print("--- [Server] 我在等连接，请启动 Client ---")

# 3. 接受连接
client_sock, address = server_sock.accept()
print(f"--- [Server] 成功！发现 Client: {address} ---")

# 4. 接收数据
data = client_sock.recv(1024)
print(f"--- [Server] 收到消息: {data.decode('utf-8')} ---")

# 5. 清理
client_sock.close()
server_sock.close()