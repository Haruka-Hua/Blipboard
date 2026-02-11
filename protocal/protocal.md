# Protocal for Blipboard

## Data structure
Message is sent between servers and clients using json format.
```json
{
    "request" : "request type",
    "dataType" : "content data type",
    "data" : "clipboard content",
    "timestamp" : 114514
}
```

## Specifications
### request
Request type from sender.
|request|meaning|
|---|---|
|PUSH|Pushes clipboard content to another device.|
|PULL|Request to pull clipboard content from another device.|

### dataType
Data type on the clipboard. Only support text currently.
|dataType|meaning|
|---|---|
|text|Plain text, which is straightly decoded to string.|

### data
Content on the clipboard. Decoded according to the data type.

### timestamp
Time when the request was sent.