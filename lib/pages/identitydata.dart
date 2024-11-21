import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/wallet.dart';

class IdentityDataEntryScreen extends StatefulWidget {
  const IdentityDataEntryScreen({super.key});

  @override
  State<IdentityDataEntryScreen> createState() =>
      _IdentityDataEntryScreenState();
}

class _IdentityDataEntryScreenState extends State<IdentityDataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  void _addData() async {
    var dataBox = await Hive.openBox<Identity>('identity');

    String name = _nameController.text;
    String number = _numberController.text;

    if (name.isNotEmpty) {
      await dataBox.add(Identity(Identity_name: name, Identity_number: number));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Save Your Identity Card',
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
                    hintText: 'Aadhar Card / PAN Card',
                    hintStyle: TextStyle(fontFamily: 'ZSpace'))),
            const SizedBox(height: 10),
            TextField(
              controller: _numberController,
              maxLength: 20,
              decoration: const InputDecoration(
                  hintText: '12345678 / XXXXX78923X',
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
                      "Save Identity Card",
                      style: TextStyle(fontSize: 20),
                    ))),
          ],
        ),
      ),
    );
  }
}
