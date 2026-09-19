import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'core/config/supabase_config.dart';
import 'core/services/supabase_client_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (skipped gracefully until keys are configured).
  if (SupabaseConfig.isConfigured) {
    try {
      await SupabaseClientService.init();
    } catch (e) {
      debugPrint('Supabase init failed (Django fallback active): $e');
    }
  } else {
    debugPrint(
      'Supabase not configured — set SUPABASE_URL / SUPABASE_ANON_KEY. '
      'Django API fallback remains active.',
    );
  }

  // Initialize flutter_downloader
  await FlutterDownloader.initialize(
    debug: true, // Set to false in production
    ignoreSsl: true, // Only use this during development
  );

  // Set system UI overlay style for Android status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const EfathaChurchApp());
}

/// Efatha Church App - Main Application Widget
class EfathaChurchApp extends StatelessWidget {
  const EfathaChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Efatha Church',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
