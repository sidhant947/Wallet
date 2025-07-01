import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wallet/models/db_helper.dart';
import 'models/provider_helper.dart';
import 'screens/homescreen.dart';
import 'package:provider/provider.dart';
// This is for testing Only
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // This is for testing Only
  // databaseFactory = databaseFactoryFfi;

  // Initialize the database before the app starts
  await Future.wait([
    DatabaseHelper.instance.database, // Initialize wallet.db
    IdentityDatabaseHelper.instance.database, // Initialize identity.db
    LoyaltyDatabaseHelper.instance.database, // Initialize loyalty.db
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (context) => WalletProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: "Bebas",
        scaffoldBackgroundColor: Colors.black,
      ),
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
  }

  Future<void> security() async {
    // This is for testing Only
    if (Platform.isLinux || kIsWeb) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      return;
    }
    // Auth Check
    final auth = LocalAuthentication();
    bool isBiometricSupported = await auth.isDeviceSupported();
    bool canCheckBiometrics = await auth.canCheckBiometrics;

    if (isBiometricSupported && canCheckBiometrics) {
      await auth.authenticate(
        localizedReason: 'Touch your finger on the sensor to login',
      );
    } else {
      // Handle the case where biometrics are not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We Recommend Using A Screen Lock for Better Security, If you keep using Without lock anyone can access your cards if they have your phone',
          ),
        ),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Secure Check"),
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
                  border: Border.all(color: Colors.white),
                ),
                child: const Text(
                  "Authenticate",
                  style: TextStyle(fontSize: 30),
                ),
              ),
              SizedBox(height: 40),
              Icon(Icons.lock, size: 50),
            ],
          ),
        ),
      ),
    );
  }
}
