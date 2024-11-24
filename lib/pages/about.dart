import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Future<void> _launchURL() async {
    final url =
        Uri.parse('upi://pay?pa=8920367120@amazonpay&pn=Sidhant&cu=INR');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

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
          GestureDetector(
            onTap: () {
              _launchURL();
            },
            child: Container(
              width: 250,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1)),
              child: const Text(
                'Donate - to support Project',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
