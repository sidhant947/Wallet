import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/wallet.dart';

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void _addData() async {
    var dataBox = await Hive.openBox<Wallet>('card');

    String name = _nameController.text;
    String number = _numberController.text;
    String expiry = _expiryController.text;

    if (name.isNotEmpty) {
      await dataBox.add(Wallet(name: name, number: number, expiry: expiry));
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextField(
                  maxLength: 20,
                  controller: _nameController,
                  decoration: const InputDecoration(
                      // labelText: 'Card Name',
                      hintText: 'Infinia',
                      hintStyle: TextStyle(fontFamily: 'ZSpace'))),
              const SizedBox(height: 10),
              TextFormField(
                controller: _numberController,
                maxLength: 16,
                decoration: const InputDecoration(
                    hintText: '1234567891234567',
                    hintStyle: TextStyle(fontFamily: 'ZSpace')),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.length < 15) {
                    return 'Please enter at least 15 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                maxLength: 4,
                controller: _expiryController,
                decoration: const InputDecoration(
                    hintText: "MMYY",
                    hintStyle: TextStyle(fontFamily: 'ZSpace')),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'Please enter at least 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                  onTap: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _addData();
                    }
                  },
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
                        "Save Card",
                        style: TextStyle(fontSize: 30),
                      ))),
            ],
          ),
        ),
      ),
    );
  }
}
