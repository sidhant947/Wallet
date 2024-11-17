import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'wallet.dart';

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  void _addData() async {
    var dataBox = await Hive.openBox<Wallet>('card');

    String name = _nameController.text;
    String number = _numberController.text;
    String expiry = _expiryController.text;
    String cvv = _cvvController.text;

    if (name.isNotEmpty) {
      await dataBox
          .add(Wallet(name: name, number: number, expiry: expiry, cvv: cvv));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Save Your Card',
          style: TextStyle(fontFamily: 'Bebas', fontSize: 30),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                maxLength: 20,
                controller: _nameController,
                decoration: const InputDecoration(
                    // labelText: 'Card Name',
                    hintText: 'Axis NEO',
                    hintStyle: TextStyle(fontFamily: 'ZSpace'))),
            const SizedBox(height: 10),
            TextField(
              controller: _numberController,
              maxLength: 16,
              decoration: const InputDecoration(
                  // labelText: 'Enter Number',
                  hintText: '1234567891234567',
                  hintStyle: TextStyle(fontFamily: 'ZSpace')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              maxLength: 4,
              controller: _expiryController,
              decoration: const InputDecoration(
                  // labelText: 'Enter Expiry',
                  hintText: "MMYY",
                  hintStyle: TextStyle(fontFamily: 'ZSpace')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              maxLength: 3,
              controller: _cvvController,
              decoration: const InputDecoration(
                  // labelText: 'CVV',
                  hintText: "000",
                  hintStyle: TextStyle(fontFamily: 'ZSpace')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            GestureDetector(
                onTap: _addData,
                child: Container(
                    height: 70,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white, // Border color
                          width: 0.09 // Border width
                          ),
                      // borderRadius: BorderRadius.circular(10),
                    ),
                    child: Lottie.asset("assets/card.json"))),
          ],
        ),
      ),
    );
  }
}
