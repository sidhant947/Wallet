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
    themeProvider.init(), // Use the new init method
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

// ... rest of the file is unchanged
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Wallet',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme, // Use the new light theme
      darkTheme: themeProvider.darkTheme, // Use the new dark theme
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStartupSettings();
    });
  }

  Future<void> _checkStartupSettings() async {
    final startupProvider = Provider.of<StartupSettingsProvider>(
      context,
      listen: false,
    );

    if (startupProvider.showAuthenticationScreen) {
      await security();
    } else {
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
    if (Platform.isLinux || kIsWeb) {
      _navigateToDefaultScreen();
      return;
    }

    final auth = LocalAuthentication();
    bool isBiometricSupported = await auth.isDeviceSupported();
    bool canCheckBiometrics = await auth.canCheckBiometrics;

    if (isBiometricSupported && canCheckBiometrics) {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access your wallet',
      );

      if (authenticated) {
        _navigateToDefaultScreen();
      } else {
        // User failed to authenticate. You might want to close the app or show an error.
      }
    } else {
      // If biometrics aren't set up, just proceed.
      _navigateToDefaultScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The splash screen can be a simple loading indicator while settings are checked.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
