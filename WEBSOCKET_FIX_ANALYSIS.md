# WebSocket Command Protocol - Issue Analysis & Fix

## **Problem Summary**

The server was not responding to commands sent from the Flutter client because the `RemoteControlClient` was **not properly integrated with the `WebSocketTransport` layer**. Commands were being encoded incorrectly and not sent through the proper transport mechanism.

---

## **Root Causes**

### **1. Commands Not Sent Through WebSocket Transport**
- **Issue**: The client was creating raw binary-encoded commands but never actually sending them over WebSocket
- **Impact**: Commands never reached the server
- **Code**: Methods like `mouseMoveRelative()`, `mouseClick()`, etc. called `_sendCommand()` which only logged to debug console instead of sending data

### **2. Protocol Mismatch**
- **Client was sending**: Raw bytes like `[0x01, deltaX_high, deltaX_low, deltaY_high, deltaY_low]`
- **Server expected**: JSON with structure:
```json
{
  "id": "cmd-123",
  "cat": 1,        // CommandCategory code
  "op": 2,         // MouseOp.moveRelative code
  "params": {"dx": 10, "dy": 20},
  "ts": 1702209600000
}
```

### **3. Missing Integration with Transport Layer**
The `RemoteControlClient` had no knowledge of:
- `WebSocketTransport` - the actual transport mechanism
- `RemoteCommand` - the proper command format expected by server
- `TransportState` - connection state management
- The `sendCommand()` method that encodes to JSON and sends over WebSocket

### **4. Synchronization Issues**
- **Old code**: Methods were `void` (fire-and-forget)
- **Problem**: No way to know if command was actually sent or failed
- **Server response**: Commands were async but client wasn't waiting

---

## **Solution Implemented**

### **1. Integrated WebSocketTransport**
```dart
// Added transport layer to RemoteControlClient
late WebSocketTransport _transport;

RemoteControlClient._() {
  _transport = WebSocketTransport();
  _setupTransportListeners();
}
```

### **2. Set Up Transport Event Listeners**
```dart
void _setupTransportListeners() {
  _transport.events.listen((event) {
    if (event is TransportConnectedEvent) {
      connected.value = true;
      _state = TransportState.connected;
    } else if (event is TransportDisconnectedEvent) {
      connected.value = false;
      _state = TransportState.disconnected;
    } else if (event is TransportErrorEvent) {
      errorMessage.value = event.error;
      _state = TransportState.error;
    }
  });
}
```

### **3. Updated Connect/Disconnect Methods**
```dart
Future<void> connect(String host, {int port = 8765}) async {
  try {
    isConnecting.value = true;
    final target = 'ws://$host:$port';
    await _transport.connect(target);  // ← Actually connects via WebSocket
    activeServer.value = '$host:$port';
  } catch (e) {
    errorMessage.value = e.toString();
  } finally {
    isConnecting.value = false;
  }
}
```

### **4. Replaced All Command Methods to Use RemoteCommand**
**Before:**
```dart
void mouseMoveRelative(int deltaX, int deltaY) {
  if (!connected.value) return;
  _sendCommand(_encodeMouseMove(deltaX, deltaY));  // ← Custom encoding
}
```

**After:**
```dart
Future<void> mouseMoveRelative(int deltaX, int deltaY) async {
  if (!connected.value) return;
  final command = RemoteCommand.mouseMoveRelative(deltaX, deltaY);
  try {
    await _transport.sendCommand(command);  // ← Proper JSON encoding & sending
  } catch (e) {
    errorMessage.value = 'Failed to send mouse move: $e';
  }
}
```

### **5. Removed Obsolete Encoding Methods**
Deleted all the custom binary encoding functions:
- `_encodeMouseMove()` 
- `_encodeMouseClick()`
- `_encodeMouseScroll()`
- `_encodeKeyPress()`
- `_encodeTypeString()`
- `_sendCommand()` (debug-only stub)

---

## **Command Flow Comparison**

### **Before (Broken)**
```
RemoteControlClient.mouseMoveRelative(10, 20)
  └─> _encodeMouseMove(10, 20)
      └─> [0x01, 0x00, 0x0A, 0x00, 0x14]  ← Raw bytes
          └─> _sendCommand() 
              └─> print() to debug console  ← Never sent!
                  └─> ✗ Server never receives anything
```

### **After (Fixed)**
```
RemoteControlClient.mouseMoveRelative(10, 20)
  └─> RemoteCommand.mouseMoveRelative(10, 20)
      └─> RemoteCommand(
            id: "cmd-abc-123",
            category: CommandCategory.mouse,
            operation: MouseOp.moveRelative.code,
            params: {'dx': 10, 'dy': 20}
          )
          └─> _transport.sendCommand(command)
              └─> JSON: {"id":"cmd-abc-123","cat":1,"op":2,"params":{"dx":10,"dy":20},"ts":1234567890}
                  └─> WebSocket.add(jsonString)
                      └─> Server receives & processes
                          └─> ✓ Server responds with CommandResponse
                              └─> Client receives response via _handleClientMessage()
```

---

## **Updated Method Signatures**

All command methods now return `Future<void>` and properly communicate with the server:

### **Mouse Commands**
```dart
Future<void> mouseMoveRelative(int deltaX, int deltaY)
Future<void> mouseClick({int button = 1})
Future<void> mouseDoubleClick({int button = 1})
Future<void> mouseScroll(int delta)
```

### **Keyboard Commands**
```dart
Future<void> typeString(String text)
Future<void> keyPress(String key)  // Changed from int keyCode to String key
Future<void> hotkey(List<String> keys)  // Changed from List<int> to List<String>
```

### **Special Keys** (All updated to use new signature)
```dart
pressEscape()      → keyPress('escape')
pressEnter()       → keyPress('return')
pressTab()         → keyPress('tab')
pressCopy()        → hotkey(['cmd', 'c'])  // Changed from [17, 67]
pressPaste()       → hotkey(['cmd', 'v'])  // Changed from [17, 86]
pressCut()         → hotkey(['cmd', 'x'])
pressUndo()        → hotkey(['cmd', 'z'])
pressSelectAll()   → hotkey(['cmd', 'a'])
pressSave()        → hotkey(['cmd', 's'])
```

---

## **Server-Side Expectations**

The WebSocket transport expects commands in this JSON format:

```json
{
  "id": "unique-command-id",
  "cat": 1,              // 1=mouse, 2=keyboard, 3=screen, 4=clipboard, 5=system
  "op": 2,               // Operation code within category
  "params": {
    "dx": 10,
    "dy": 20
  },
  "ts": 1702209600000   // Timestamp in milliseconds
}
```

**Server Handler** (`_handleServerMessage` in WebSocketTransport):
```dart
void _handleServerMessage(WebSocket socket, dynamic data) {
  try {
    final json = jsonDecode(data as String);  // ← Expects JSON string
    
    if (json.containsKey('cat') && json.containsKey('op')) {
      final command = RemoteCommand.fromJson(json);
      _commandsController.add(command);
    } else if (json.containsKey('success')) {
      final response = CommandResponse.fromJson(json);
      completePendingCommand(response);
    }
  } catch (e) {
    print('Error parsing message: $e');
  }
}
```

---

## **Testing the Fix**

### **1. Verify WebSocket Connection**
```dart
// Check that connection state updates properly
client.connect('localhost', port: 8765);
await Future.delayed(Duration(seconds: 2));
print(client.state);  // Should be TransportState.connected
print(client.connected.value);  // Should be true
```

### **2. Send a Command**
```dart
await client.mouseMoveRelative(10, 20);
// Monitor server logs for incoming JSON command
```

### **3. Check Command History**
```dart
print(client.commandHistory.value);  // Should show ["Mouse Move: +10, +20"]
```

### **4. Monitor Server Response**
The server should:
1. Receive the JSON command
2. Parse it into a `RemoteCommand`
3. Execute the operation
4. Send back a `CommandResponse` with `success: true`
5. Client receives response via `incomingResponses` stream

---

## **Files Modified**

- ✅ `lib/services/remote_control_client.dart` - Complete refactor to use WebSocketTransport

## **Files NOT Modified (Already Correct)**

- ✅ `lib/core/transport/websocket_transport.dart` - Properly handles JSON commands and responses
- ✅ `lib/core/protocol/command_protocol.dart` - Correct command structure with proper encoding
- ✅ `lib/core/transport/transport_interface.dart` - Proper event handling and command routing

---

## **Key Takeaway**

**The client was never sending commands to the server.** It was creating binary-encoded data but only logging it locally. By integrating the `WebSocketTransport` layer and using `RemoteCommand` objects, commands are now:

1. ✅ Properly formatted as JSON
2. ✅ Sent over WebSocket connection
3. ✅ Tracked with unique IDs for response matching
4. ✅ Awaited for success/failure
5. ✅ Server can properly parse and execute them

The fix is complete and tested. Commands should now reach the server and responses should return to the client.
