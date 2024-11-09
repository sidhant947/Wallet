import 'package:flutter/material.dart';
import 'hive.dart';

class DataEntryScreen extends StatefulWidget {
  @override
  _DataEntryScreenState createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  void _addData() async {
    var dataBox = await openBox();

    String _name = _nameController.text;
    String _number = _numberController.text;
    String _expiry = _expiryController.text;
    String _cvv = _cvvController.text;

    if (_name.isNotEmpty &&
        _number.isNotEmpty &&
        _expiry.isNotEmpty &&
        _cvv.isNotEmpty) {
      dataBox.add(
          {'name': _name, 'number': _number, 'expiry': _expiry, 'cvv': _cvv});
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' New Card Added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Data'),
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
            SizedBox(height: 10),
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
            SizedBox(height: 10),
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
            SizedBox(height: 10),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addData,
              child: Container(
                padding: EdgeInsets.all(15),
                child: Text(
                  'Save Card',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
