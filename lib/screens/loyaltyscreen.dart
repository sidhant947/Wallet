import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import '../models/db_helper.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  List<Loyalty>? loyalties;

  @override
  void initState() {
    super.initState();
    _loadLoyalties();
  }

  // Load loyalties from SQLite database
  Future<void> _loadLoyalties() async {
    loyalties = (await LoyaltyDatabaseHelper.instance.getAllLoyalties())
        .cast<Loyalty>();
    setState(() {});
  }

  void _removeData(BuildContext context, int id) async {
    await LoyaltyDatabaseHelper.instance.deleteLoyalty(id);
    _loadLoyalties(); // Reload the list after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loyalty Card Deleted'),
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      print('Text copied to clipboard!');
    }).catchError((e) {
      print('Error copying to clipboard: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: const Text(
          "Loyalty Cards",
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const LoyaltyDataEntryScreen()),
          );
          if (result != null) {
            _loadLoyalties(); // Reload list after new Loyalty is added
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.fingerprint),
      ),
      body: Column(
        children: [
          loyalties == null
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: loyalties!.isEmpty
                      ? Center(
                          child: Lottie.asset("assets/loading.json"),
                        )
                      : ListView.builder(
                          itemCount: loyalties!.length,
                          itemBuilder: (context, index) {
                            var Loyalty = loyalties![index];
                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Slidable(
                                key: ValueKey(index),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (BuildContext context) {
                                        _removeData(context, Loyalty.id!);
                                      },
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white.withOpacity(0.2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.cyan.withOpacity(0.5),
                                          blurRadius: 125,
                                          spreadRadius: 10),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        alignment: Alignment.topLeft,
                                        margin: const EdgeInsets.all(10.0),
                                        child: Text(Loyalty.loyaltyName,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Bebas',
                                                fontSize: 28)),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          copyToClipboard(
                                              Loyalty.loyaltyNumber);
                                        },
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          margin: const EdgeInsets.all(10.0),
                                          child: Text(
                                            Loyalty.loyaltyNumber,
                                            style: const TextStyle(
                                                letterSpacing: 1, fontSize: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}

class LoyaltyDataEntryScreen extends StatefulWidget {
  const LoyaltyDataEntryScreen({super.key});

  @override
  State<LoyaltyDataEntryScreen> createState() => _LoyaltyDataEntryScreenState();
}

class _LoyaltyDataEntryScreenState extends State<LoyaltyDataEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  void _addData() async {
    String name = _nameController.text.trim();
    String number = _numberController.text.trim();

    // Validate input
    if (name.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out both fields.'),
        ),
      );
      return;
    }

    try {
      // Create new Loyalty object
      Loyalty newLoyalty = Loyalty(loyaltyName: name, loyaltyNumber: number);

      // Insert the new Loyalty into the database
      int id = await LoyaltyDatabaseHelper.instance.insertLoyalty(newLoyalty);
      print("Inserted ID: $id");

      // Optionally show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loyalty card saved successfully.'),
        ),
      );

      // Pop the screen to go back
      Navigator.pop(context, true);
    } catch (e) {
      // Handle any errors during insertion
      print("Error inserting Loyalty: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving Loyalty card.'),
        ),
      );
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
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Starbucks',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                hintText: 'ABS9237498',
                hintStyle: TextStyle(fontFamily: 'ZSpace'),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _addData,
              child: Container(
                padding: const EdgeInsets.all(5),
                width: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
                child: const Text(
                  "Save Loyalty Card",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
