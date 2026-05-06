import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snaptube/core/bindings/app_bindings.dart';
import 'package:snaptube/core/theme/app_theme.dart';
import 'package:snaptube/screens/root_screen.dart';

/// SnapTube — YouTube Video & Shorts Downloader
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SnapTubeApp());
}

class SnapTubeApp extends StatelessWidget {
  const SnapTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SnapTube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      initialBinding: AppBindings(),
      home: const RootScreen(),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
