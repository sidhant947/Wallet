import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Center(
          child: Text(
        "Made by Sidhant",
        style: TextStyle(fontSize: 30),
      )),
    );
  }
}
