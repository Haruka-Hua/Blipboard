import platform
import socket
import pyperclip
import uuid
import transmission.transmission
import subprocess

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
    This function ends when the client is disconnected.
    
    :param client_sock: client socket
    :type client_sock: socket.socket
    """
    client_sock.settimeout(1.0)
    while True:
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

def run_server() -> None:
    """
    Run the server: listen and connect.
    """
    SERVER_MAC = get_mac()
    print(f"Server MAC address: {SERVER_MAC}")
    PORT = 4
    # create socket
    server_sock = socket.socket(socket.AF_BLUETOOTH,socket.SOCK_STREAM,socket.BTPROTO_RFCOMM)
    try:
        # bind and listen
        server_sock.bind((SERVER_MAC,PORT))
        server_sock.listen(1)
        server_sock.settimeout(1.0)
        print(f"[Server] Service started, listening to port {PORT} ...")
        print("[Server] Waiting for connection, enter Ctrl+C to exit.")
        while True:
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
    except KeyboardInterrupt:
        print("[Server] Exiting ...")
    except Exception as e:
        print(f"[Server] Error: {e}")
    finally:
        server_sock.close()
        print("[Server] Server closed!")

if __name__=="__main__":
    run_server()