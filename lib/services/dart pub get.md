dart pub get
dart compile exe bin/server.dart -o dart-manager
sudo mv dart-manager /usr/local/bin/

#### Step 2: Install as a Service (Root Access)
Run the install command with sudo. This handles your requirement for setting up background execution and root access.

```bash
sudo dart-manager install

**Output:**
It will setup the systemd service and, most importantly, **print an API Token**.
```text
---------------------------------------------
Service Installed and Started!
Use this Token in your Flutter App:

   a8s7d87as8d7a8sd787asd87a8sd...   

---------------------------------------------

#### Step 3: Connect from Flutter
In your Flutter app, use the `web_socket_channel` package.
Note that we implemented a logic where the **first message** sent must be the auth token.

```dart
// Flutter Client Logic Mockup
final channel = IOWebSocketChannel.connect('ws://YOUR_SERVER_IP:8080');

// 1. Send Auth Immediately
channel.sink.add(jsonEncode({
  'type': 'auth', 
  'token': 'THE_TOKEN_FROM_STEP_2'
}));

// 2. Listen
channel.stream.listen((message) {
  print('Server says: $message');
});

#### Step 4: Uninstalling
If you want to clean the server, simply run:

```bash
sudo dart-manager uninstall

### Why not use System SSH Passwords?
1.  **Permissions:** To verify a Linux password, your Dart app needs read access to `/etc/shadow`, which is highly sensitive.
2.  **Security:** Sending your *root* password over a WebSocket (even with SSL) is dangerous. If the Flutter app is compromised or logs are intercepted, your entire server is gone.
3.  **Stability:** Using a generated Token (as shown above) allows you to revoke access by simply deleting the config file, without changing the actual server root password.