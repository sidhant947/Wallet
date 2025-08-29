import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'models/provider_helper.dart';
import 'screens/homescreen.dart';
import 'screens/identityscreen.dart';
import 'screens/loyaltyscreen.dart';
import 'package:provider/provider.dart';
// This is for testing Only
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // This is for testing Only
  // databaseFactory = databaseFactoryFfi;

  // Initialize providers and load saved preferences
  final themeProvider = ThemeProvider();
  final startupProvider = StartupSettingsProvider();

  await Future.wait([
    themeProvider.loadThemePreference(),
    startupProvider.loadStartupSettings(),
  ]);

  // Initialize the database before the app starts
  await Future.wait([
    DatabaseHelper.instance.database, // Initialize wallet.db
    IdentityDatabaseHelper.instance.database, // Initialize identity.db
    LoyaltyDatabaseHelper.instance.database, // Initialize loyalty.db
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WalletProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: startupProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: themeProvider.useSystemFont ? null : "Bebas",
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        // cardTheme: CardTheme(color: Colors.grey.shade100, elevation: 2),
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Colors.black,
            fontFamily: themeProvider.useSystemFont ? null : "Bebas",
          ),
          bodyMedium: TextStyle(
            color: Colors.black87,
            fontFamily: themeProvider.useSystemFont ? null : "Bebas",
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.blue.shade600,
          secondary: Colors.blueAccent.shade400,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: themeProvider.useSystemFont ? null : "Bebas",
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        // cardTheme: CardTheme(color: Colors.grey.shade900, elevation: 2),
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.black),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Colors.white,
            fontFamily: themeProvider.useSystemFont ? null : "Bebas",
          ),
          bodyMedium: TextStyle(
            color: Colors.white70,
            fontFamily: themeProvider.useSystemFont ? null : "Bebas",
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.blueAccent.shade400,
          surface: Colors.grey.shade900,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      themeMode: themeProvider.currentTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling navigation during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStartupSettings();
    });
  }

  Future<void> _checkStartupSettings() async {
    final startupProvider = Provider.of<StartupSettingsProvider>(
      context,
      listen: false,
    );

    if (!startupProvider.showAuthenticationScreen) {
      // Skip authentication and go directly to the default screen
      _navigateToDefaultScreen();
    }
  }

  void _navigateToDefaultScreen() {
    final startupProvider = Provider.of<StartupSettingsProvider>(
      context,
      listen: false,
    );
    Widget targetScreen;

    switch (startupProvider.defaultScreen) {
      case StartupScreen.home:
        targetScreen = const HomeScreen();
        break;
      case StartupScreen.loyalty:
        targetScreen = const LoyaltyScreen();
        break;
      case StartupScreen.identity:
        targetScreen = const IdentityScreen();
        break;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  Future<void> security() async {
    // This is for testing Only
    if (Platform.isLinux || kIsWeb) {
      _navigateToDefaultScreen();
      return;
    }

    // Auth Check
    final auth = LocalAuthentication();
    bool isBiometricSupported = await auth.isDeviceSupported();
    bool canCheckBiometrics = await auth.canCheckBiometrics;

    if (isBiometricSupported && canCheckBiometrics) {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Touch your finger on the sensor to login',
      );

      if (authenticated) {
        _navigateToDefaultScreen();
      }
    } else {
      // Handle the case where biometrics are not available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We Recommend Using A Screen Lock for Better Security, If you keep using Without lock anyone can access your cards if they have your phone',
            ),
          ),
        );
      }
      _navigateToDefaultScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final startupProvider = Provider.of<StartupSettingsProvider>(context);

    // If authentication is disabled, show loading screen while navigating
    if (!startupProvider.showAuthenticationScreen) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [SizedBox(height: 20), Text('Loading...')],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Check"),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: GestureDetector(
        onTap: security,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purpleAccent),
                ),
                child: const Text(
                  "Authenticate",
                  style: TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(height: 40),
              const Icon(Icons.lock, size: 50),
            ],
          ),
        ),
      ),
    );
  }
}
