import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'pages/splash_screen.dart';
import 'models/scene/data_model.dart';

void main() {
  // Initialize container registry before app starts
  ContainerRegistry.registerBuiltIns();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Socketify - Server Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              centerTitle: false,
              elevation: 2,
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
