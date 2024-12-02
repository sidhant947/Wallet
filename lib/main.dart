import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'screens/homescreen.dart';
import 'models/wallet.dart'; // Make sure to import the Card model class

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (make sure to call Hive.initFlutter() for Flutter projects)
  await Hive.initFlutter();

  // Register the generated adapter for Card
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(LoyaltyAdapter());
  Hive.registerAdapter(IdentityAdapter());

  runApp(const MyApp());
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
    return Scaffold(
      body: GestureDetector(
        onTap: security,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(border: Border.all(color: Colors.white)),
            child: const Text(
              "Authenticate",
              style: TextStyle(fontSize: 30),
            ),
          ),
        ),
      ),
    );
  }
}
