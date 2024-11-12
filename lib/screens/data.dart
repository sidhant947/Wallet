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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New Card Added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Save Your Card',
          style: TextStyle(fontSize: 20),
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
                labelText: 'Enter Name of Card',
                hintText: 'Axis NEO',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _numberController,
              maxLength: 16,
              decoration: const InputDecoration(
                labelText: 'Enter Number',
                hintText: '1234567891234567',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              maxLength: 4,
              controller: _expiryController,
              decoration: const InputDecoration(
                labelText: 'Enter Expiry',
                hintText: "MMYY",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              maxLength: 3,
              controller: _cvvController,
              decoration: const InputDecoration(
                labelText: 'CVV',
                hintText: "000",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addData,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(300, 75),
              ),
              child:
                  SizedBox(height: 70, child: Lottie.asset("assets/card.json")),
            ),
          ],
        ),
      ),
    );
  }
}
