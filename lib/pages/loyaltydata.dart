import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/wallet.dart';

class LoyaltyDataEntryScreen extends StatefulWidget {
  const LoyaltyDataEntryScreen({super.key});

  @override
  State<LoyaltyDataEntryScreen> createState() => _LoyaltyDataEntryScreenState();
}

class _LoyaltyDataEntryScreenState extends State<LoyaltyDataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  void _addData() async {
    var dataBox = await Hive.openBox<Loyalty>('loyalty');

    String name = _nameController.text;
    String number = _numberController.text;

    if (name.isNotEmpty) {
      await dataBox.add(Loyalty(loyalty_name: name, loyalty_number: number));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Save Your Loyalty Card',
          style: TextStyle(fontFamily: 'Bebas', fontSize: 25),
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
                    hintText: 'Brand Name',
                    hintStyle: TextStyle(fontFamily: 'ZSpace'))),
            const SizedBox(height: 10),
            TextField(
              controller: _numberController,
              maxLength: 16,
              decoration: const InputDecoration(
                  hintText: 'Barcode Number',
                  hintStyle: TextStyle(fontFamily: 'ZSpace')),
            ),
            GestureDetector(
                onTap: _addData,
                child: Container(
                    padding: const EdgeInsets.all(5),
                    width: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                      ),
                    ),
                    child: const Text(
                      "Save Loyalty Card",
                      style: TextStyle(fontSize: 25),
                    ))),
          ],
        ),
      ),
    );
  }
}
