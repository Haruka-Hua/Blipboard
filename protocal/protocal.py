import json
import time

def pack_data(request:str, data:str="", dataType="text")->bytes:
    """
    Pack information into JSON byte streams. 
    """
    msg = {
        "request" : request,
        "dataType" : dataType,
        "data" : data,
        "timestamp" : time.time()
    }
    json_str = json.dumps(msg)
    return json_str.encode('utf-8')

def unpack_data(raw_bytes:bytes)->dict:
    """
    Unpack raw bytes into information.
    """
    json_str = raw_bytes.decode('utf-8')
    return json.loads(json_str)