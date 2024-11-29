import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "About",
          style: TextStyle(fontFamily: "ZenDots"),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Center(
          child: Column(
        children: [
          Lottie.asset("assets/dev.json"),
          const Text(
            "Made by Sidhant",
            style: TextStyle(fontFamily: 'ZenDots', fontSize: 25),
          ),
          const SizedBox(
            height: 30,
          ),
        ],
      )),
    );
  }
}
