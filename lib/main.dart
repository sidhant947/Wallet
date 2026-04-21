import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/encryption_service.dart';
import 'models/provider_helper.dart';
import 'screens/homescreen.dart';
import 'package:provider/provider.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This is for testing Only
  // databaseFactory = databaseFactoryFfi;

  // Initialize AES-256 encryption service BEFORE any database operations.
  // This generates (or loads) the master encryption key from secure storage.
  await EncryptionService.instance.init();

  final themeProvider = ThemeProvider();
  final startupProvider = StartupSettingsProvider();

  await Future.wait([
    themeProvider.init(),
    startupProvider.loadStartupSettings(),
  ]);

  await Future.wait([
    DatabaseHelper.instance.database,
    IdentityDatabaseHelper.instance.database,
    LoyaltyDatabaseHelper.instance.database,
  ]);

  // One-time migration: encrypt any existing plaintext data in the databases.
  if (!await EncryptionService.instance.isMigrated()) {
    debugPrint('Running one-time encryption migration...');
    await Future.wait([
      DatabaseHelper.instance.migrateToEncrypted(),
      IdentityDatabaseHelper.instance.migrateToEncrypted(),
      LoyaltyDatabaseHelper.instance.migrateToEncrypted(),
    ]);
    await EncryptionService.instance.markMigrated();
    debugPrint('Encryption migration complete.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WalletProvider()),
        ChangeNotifierProvider(create: (context) => LoyaltyProvider()),
        ChangeNotifierProvider(create: (context) => IdentityProvider()),
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
    return Selector<ThemeProvider, ({ThemeMode themeMode, bool useSystemFont})>(
      selector: (_, provider) => (
        themeMode: provider.currentTheme,
        useSystemFont: provider.useSystemFont,
      ),
      builder: (context, data, _) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        return MaterialApp(
          title: 'Wallet',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: data.themeMode,
          home: const SplashScreen(),
        );
      },
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
      await _performAuthentication();
    } else {
      _navigateToHomeScreen();
    }
  }

  void _navigateToHomeScreen() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  Future<void> _performAuthentication() async {
    if (Platform.isLinux || kIsWeb) {
      _navigateToHomeScreen();
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
        _navigateToHomeScreen();
      }
    } else {
      _navigateToHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: isDark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF0F0F0),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE0E0E0),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Icon(Icons.wallet_rounded, size: 56, color: textColor),
              ),
            ),
            const SizedBox(height: 32),
            // App name
            Text(
              'WALLET',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Secure • Simple • Smart',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF5F5F5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
