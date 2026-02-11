import socket
import pyperclip
import time
import keyboard
import protocal.protocal

server_mac = input("Please enter the target server's MAC address: ")
server_mac.replace('-',':')
port = 4

client_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)
print(f"[Client] Trying to connect to {server_mac}")

try:
    # connect server
    print("[Client] Connecting...")
    client_sock.connect((server_mac, port))
    print("[Client] Connected successfully!")
    print("--- Blipboard Guide ---")
    print("Ctrl + Alt + C : Push local clipboard content to server.")
    print("Ctrl + Alt + V : Pull server clipboard content to local.")
    print("Ctrl + C at this window: Exit.")

    # get clipboard content
    last_content = pyperclip.paste()
    while True:
        if keyboard.is_pressed("ctrl+alt+c"):
            # push req
            content = pyperclip.paste()
            if content:
                print("[Client] Pushing clipboard content ...")
                packet = protocal.protocal.pack_data(
                    request="PUSH",
                    data=content,
                    dataType="text"
                )
                client_sock.send(packet)
                print("[Client] Push success!")
                time.sleep(0.5)
        elif keyboard.is_pressed("ctrl+alt+v"):
            # pull req
            print("[Client] Sending pull request ...")
            packet = protocal.protocal.pack_data(request="PULL")
            client_sock.send(packet)
            raw_data = client_sock.recv(4096)
            if raw_data:
                message = protocal.protocal.unpack_data(raw_data)
                if message and message["request"]=="PUSH":
                    pyperclip.copy(message["data"])
                    print("[Client] Pull success! Clipboard updated.")
            time.sleep(0.5)
        time.sleep(0.01)

except KeyboardInterrupt:
    print("[Client] Exiting ...")
except Exception as e:
    print(f"[Client] Error: {e}")
finally:
    client_sock.close()
    print("[Client] Blipboard client closed.")