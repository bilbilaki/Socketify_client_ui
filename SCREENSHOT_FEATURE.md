# Screenshot Capture Feature

## Overview
Added a new **"Screenshot"** tab to the Remote Control page that allows you to:
- Send a screen capture request to the connected server
- Receive and display the screenshot in the app
- View capture status and errors

## Features

### Tab Details
- **Tab Name**: Screenshot
- **Icon**: Camera icon
- **Position**: 3rd tab (between Keyboard and History)

### Button Actions
- **Capture Screen Button**: Sends a `captureBase64` command to the server
  - Shows loading spinner while capturing
  - Disabled when not connected
  - Disabled while capturing

### Display
- Shows the captured screenshot with rounded corners
- Displays status message when screenshot is captured
- Shows placeholder message when no screenshot yet
- Shows connection required message when disconnected

## How It Works

### 1. User Clicks "Capture Screen"
```dart
_captureScreen() is called
```

### 2. Command is Created
```dart
RemoteCommand(
  category: CommandCategory.screen,      // 0x03
  operation: ScreenOp.captureBase64,     // 0x04
)
```

### 3. Command Sent Over WebSocket
```json
{
  "id": "1702209600000",
  "cat": 3,
  "op": 4,
  "params": {},
  "ts": 1702209600000
}
```

### 4. Server Captures Screen
- Takes screenshot of remote display
- Encodes it as base64 string

### 5. Server Sends Response
```json
{
  "id": "1702209600000",
  "success": true,
  "data": "iVBORw0KGgoAAAANS...",
  "ts": 1702209600100
}
```

### 6. App Receives & Displays
- Decodes base64 data back to image bytes
- Displays with `Image.memory()`
- Shows success message

## Implementation Details

### New Method in RemoteControlClient
```dart
Future<CommandResponse> capture(RemoteCommand command)
```
- Validates connection
- Records command in history
- Sends through WebSocket transport
- Returns response with image data

### New Tab UI
```dart
- Centered layout
- Button with loading indicator
- Image display area with rounded corners
- Status/error messages
```

### State Management
```dart
_screenshotData     // Stores image bytes
_isLoadingScreenshot // Loading indicator
```

## Server Requirements

Your server must:
1. Listen for commands with `cat: 3` (screen) and `op: 4` (captureBase64)
2. Capture the desktop/remote screen
3. Encode image as base64 string
4. Send response with base64 in `data` field

Example server response:
```dart
CommandResponse(
  commandId: "1702209600000",
  success: true,
  data: "iVBORw0KGgoAAAANS..." // base64 encoded PNG/JPG
)
```

## Testing

1. **Connect to Server**
   - Enter host and port
   - Click Connect
   - Wait for connected state

2. **Navigate to Screenshot Tab**
   - Click the "Screenshot" tab in app bar

3. **Capture Screen**
   - Click "Capture Screen" button
   - Wait for image to load
   - Image displays on success

4. **Error Handling**
   - If server doesn't respond, shows error message
   - If not connected, button is disabled
   - Timeout error after 30 seconds (default)

## Files Modified
- `lib/pages/remote_control_page.dart` - Added screenshot tab UI
- `lib/services/remote_control_client.dart` - Added `capture()` method
