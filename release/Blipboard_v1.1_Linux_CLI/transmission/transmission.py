import json
import time
import struct
import socket
from typing import Any

def pack_data(request:str, data:str="", dataType="text") -> bytes:
    """
    Pack information into byte streams. 
    
    :param request: Request type
    :type request: str
    :param data: Clipboard content
    :type data: str
    :param dataType: Clipboard content type
    :return: Packed bytes
    :rtype: bytes
    """
    msg = {
        "request" : request,
        "dataType" : dataType,
        "data" : data,
        "timestamp" : time.time()
    }
    json_bytes = json.dumps(msg).encode('utf-8')
    header = struct.pack("!I",len(json_bytes))
    return header + json_bytes

def unpack_data(raw_bytes:bytes) -> dict:
    """
    Unpack byte streams into information.

    :param raw_bytes: Byte stream to decode
    :type raw_bytes: bytes
    :return: Information dict
    :rtype: dict[Any, Any]
    """
    json_str = raw_bytes.decode('utf-8')
    return json.loads(json_str)

def recv_data(sock:socket.socket) -> Any:
    """
    Receive and unpack transmitted data.
    
    :param sock: Socket to receive data from
    :type sock: socket.socket
    :return: Information dict
    :rtype: bytes
    """
    try:
        header = sock.recv(4)
    except socket.timeout:
        raise
    if not header:
        return None
    total_len = struct.unpack("!I",header)[0]
    original_timeout = sock.gettimeout()
    sock.settimeout(None)
    try:
        json_bytes_arr = []
        bytes_received = 0
        while total_len > bytes_received:
            chunk = sock.recv(min(4096,total_len-bytes_received))
            if not chunk:
                raise RuntimeError("Socket connection broken.")
            bytes_received += len(chunk)
            json_bytes_arr.append(chunk)
        json_bytes = b"".join(json_bytes_arr)
        return unpack_data(json_bytes)
    finally:
        sock.settimeout(original_timeout)