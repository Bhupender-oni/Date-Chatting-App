import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://nwkgyjvdsjslogophdwk.supabase.co',
      anonKey: 'sb_publishable_3ZgTWhQfagKfTb8PNkPkMw_IHTbIdhV',
      debug: false,
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing Supabase: $e');
  }

  runApp(const LoveMatchApp());
}

final supabase = Supabase.instance.client;
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class LoveMatchApp extends StatelessWidget {
  const LoveMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoveMatch',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.pink,
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          final session = snapshot.data?.session;
          if (session != null) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
