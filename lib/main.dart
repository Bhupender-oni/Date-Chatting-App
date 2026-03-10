import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';

//Create a supabase client
final supabase = Supabase.instance.client;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

try {
  await Supabase.initialize(
    url: 'https://nwkgyjvdsjslogophdwk.supabase.co',
    anonKey: 'sb_publishable_3ZgTWhQfagKfTb8PNkPkMw_IHTbIdhV',
    debug:true,
  );
debugPrint('Supabase initialized successfully');
} catch (e) {
  debugPrint('Error initializing Supabase: $e');
}

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{
  //Track authentication state
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentSession();
    _setupAuthListener();
  }

  //Check if user is already logged in
  Future<void> _checkCurrentSession() async {
    try{
      final session = supabase.auth.currentSession;
      setState(() {
        _isLoggedIn = session != null;
        _isLoading = false;
      });
      debugPrint('Current session exists: ${session != null}');
    } catch (e) {
      debugPrint('Error checking session: $e');
      setState(() => _isLoading = false);
    }
  }

  //Listen to auth changes
  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen(
      (data) {
        final AuthChangeEvent event = data.event;
        final session = data.session;

        debugPrint('Auth event: $event');

        if(mounted) {
          setState(() {
            _isLoggedIn = session != null;
          });
        }

        //Handle different auth events
        if(event == AuthChangeEvent.signedIn) {
          debugPrint('User signed in: ${session?.user.email}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome!'),
                backgroundColor: Colors.green,
              ),
            );         
          }
        } else if (event == AuthChangeEvent.signedOut) {
          debugPrint('User signed Out');
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged out successfully'),
                backgroundColor: Colors.orange,              
              ),
            );
          }
        } else if(event == AuthChangeEvent.userUpdated) {
          debugPrint('User updated');
        } else if( event == AuthChangeEvent.passwordRecovery) {
          debugPrint('Password recovery event');
        }
      },
      onError: (error) {
        debugPrint('Auth listener error: $error');
      }
        );
      }

      @override
      Widget build(BuildContext context) {
        // Showing loading screen
        if(_isLoading) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.pink),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'Dating App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.pink,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.pink, width: 2),
              ),
            ),
          ),
          //Set initial route based on loging status
          initialRoute: _isLoggedIn ? '/home': '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
          //Handle unknown routes
          onUnknownRoute: (settings) {
            debugPrint('Unknown route: ${settings.name}');
            return MaterialPageRoute(
              builder: (context) => _isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
            );
          },
        );
      }
}

//Optional: Global key for showing snackbars from anywhere
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();
