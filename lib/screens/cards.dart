import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BankCards extends StatefulWidget {
  const BankCards({super.key});

  @override
  State<BankCards> createState() => _BankCardsState();
}

class _BankCardsState extends State<BankCards> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text(
            "Cards With guide -Coming Soon \n Beginners ? Fuel? Premium?",
            style: TextStyle(fontSize: 20),
          ),
          Lottie.asset("assets/card.json"),
        ],
      ),
    );
  }
}
