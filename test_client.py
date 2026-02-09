import socket

# 【关键】填入你刚才查到的 A 电脑 MAC 地址
target_mac = "C8:6E:08:E2:5C:E7" 

# 1. 创建蓝牙 Socket
client_sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)

print(f"--- [Client] 尝试连接到 {target_mac} ---")

try:
    # 2. 发起连接 (端口号必须和 Server 一致，都是 1)
    client_sock.connect((target_mac, 1))
    print("--- [Client] 连接成功！ ---")
    
    # 3. 发送数据
    client_sock.send("Hello Blipboard!".encode('utf-8'))
    print("--- [Client] 消息已送达 ---")
    
except Exception as e:
    print(f"--- [Client] 失败了: {e} ---")
finally:
    client_sock.close()