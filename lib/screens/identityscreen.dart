import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:wallet/models/db_helper.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  List<Identity>? identities;

  @override
  void initState() {
    super.initState();
    _loadIdentities();
  }

  // Load identities from SQLite database
  Future<void> _loadIdentities() async {
    identities = await IdentityDatabaseHelper.instance.getAllIdentities();
    setState(() {});
  }

  void _removeData(BuildContext context, int id) async {
    await IdentityDatabaseHelper.instance.deleteIdentity(id);
    _loadIdentities(); // Reload the list after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identity Card Deleted'),
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
          "Identity Cards",
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const IdentityDataEntryScreen()),
          );
          if (result != null) {
            _loadIdentities(); // Reload list after new identity is added
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.fingerprint),
      ),
      body: Column(
        children: [
          identities == null
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: identities!.isEmpty
                      ? Center(
                          child: Lottie.asset("assets/loading.json"),
                        )
                      : ListView.builder(
                          itemCount: identities!.length,
                          itemBuilder: (context, index) {
                            var identity = identities![index];
                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Slidable(
                                key: ValueKey(index),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (BuildContext context) {
                                        _removeData(context, identity.id!);
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
                                        child: Text(identity.identityName,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Bebas',
                                                fontSize: 28)),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          copyToClipboard(
                                              identity.identityNumber);
                                        },
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          margin: const EdgeInsets.all(10.0),
                                          child: Text(
                                            identity.identityNumber,
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
      // Create new Identity object
      Identity newIdentity =
          Identity(identityName: name, identityNumber: number);

      // Insert the new identity into the database
      int id =
          await IdentityDatabaseHelper.instance.insertIdentity(newIdentity);
      print("Inserted ID: $id");

      // Optionally show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identity card saved successfully.'),
        ),
      );

      // Pop the screen to go back
      Navigator.pop(context, true);
    } catch (e) {
      // Handle any errors during insertion
      print("Error inserting identity: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving identity card.'),
        ),
      );
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
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Aadhar Card / PAN Card',
                hintStyle: TextStyle(fontFamily: 'ZSpace'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                hintText: '12345678 / XXXXX78923X',
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
                  "Save Identity Card",
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
