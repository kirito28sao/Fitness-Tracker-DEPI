import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import 'dart:developer' as developer;

// Import screens and providers
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/health_provider.dart';
import 'providers/user_profile_provider.dart';
import 'utils/theme.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    developer.log('Flutter binding initialized');

    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
      developer.log('Environment variables loaded');
    } catch (e) {
      developer.log('Error loading .env file: $e', error: e);
      // Continue without .env file for now
    }

    // Initialize Supabase
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        developer.log('Supabase credentials not found in .env file');
        // Use default values or handle the error appropriately
      } else {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        developer.log('Supabase initialized successfully');
      }
    } catch (e) {
      developer.log('Error initializing Supabase: $e', error: e);
      // Continue without Supabase for now
    }

    // Initialize Yandex Mobile Ads
    try {
      await MobileAds.initialize();
      developer.log('Yandex Mobile Ads initialized successfully');
    } catch (e) {
      developer.log('Error initializing Yandex Mobile Ads: $e', error: e);
      // Continue without ads for now
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    developer.log('Error in main(): $e', error: e, stackTrace: stackTrace);
    // Show error UI
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Fitness Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.user != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
