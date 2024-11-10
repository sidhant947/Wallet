import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
      ),
      body: const Center(
          child: Text(
        "Made by Sidhant",
        style: TextStyle(fontSize: 25),
      )),
    );
  }
}
