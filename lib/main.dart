import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallet/models/db_helper.dart';
import 'models/provider_helper.dart';
import 'screens/homescreen.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

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
    final auth = LocalAuthentication();

    await auth.authenticate(
        localizedReason: 'Touch your finger on the sensor to login');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: security,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.white)),
              child: const Text(
                "Authenticate",
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
