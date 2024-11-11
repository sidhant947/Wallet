import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/homescreen.dart';
import 'screens/wallet.dart'; // Make sure to import the Card model class

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (make sure to call Hive.initFlutter() for Flutter projects)
  await Hive.initFlutter();

  // Register the generated adapter for Card
  Hive.registerAdapter(WalletAdapter()); // Register the adapter

  // Open the Hive box before running the app
  await Hive.openBox<Wallet>('card');
// Open a box to store the Card objects

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
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}
