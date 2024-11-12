import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Center(
          child: Column(
        children: [
          Lottie.asset("assets/dev.json"),
          const Text(
            "Made by Sidhant",
            style: TextStyle(fontSize: 25),
          ),
        ],
      )),
    );
  }
}
