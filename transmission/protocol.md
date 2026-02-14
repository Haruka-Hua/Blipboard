# Protocol for Blipboard

## Data structure
A single message consists of a 4-byte header recording the length of the message, and a dictionary packed to json format that contains the details.
```
[header][encoded json data]
|4 bytes|as long as possible|
```
The json data detail is as follow:
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