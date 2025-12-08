import 'package:cross_platform_video_thumbnails/cross_platform_video_thumbnails.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as pr;
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'explorer/providers/local_provider.dart';
import 'explorer/providers/zip_explorer_provider.dart';
import 'explorer/services/user_data_service.dart';
import 'pages/splash_screen.dart';
import 'models/scene/data_model.dart';

void main() async {
  // Initialize container registry before app starts
  ContainerRegistry.registerBuiltIns();
WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
    await CrossPlatformVideoThumbnails.initialize();

   runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocalProvider()),
                ChangeNotifierProvider(
          create: (context) => ZipExplorerProvider()
        ),
                ChangeNotifierProvider(
          create: (context) => UserDataService(),
        ), // Add UserDataService


        ChangeNotifierProvider(
          create: (context) => UserDataService(),
        ), // Add UserDataService
      ],

   child:    pr.ProviderScope(
  overrides: [
      // Provide the already-initialized instance so the app uses the same AppDataManager
              // movieProvider.overrideWith((ref)=> MovieProvider()),
              // tvSeriesProvider.overrideWith((ref)=> TvSeriesProvider()),
              // animeProvider.overrideWith((ref)=> AnimeProvider()),
//              tvSeriesUnisqueseriesNameChangeNotifierProvider.overrideWith((ref)=> tvSe)

  
      ],
      child:  MyApp(), // Use const if MyApp is stateless
    ),
  ));
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
