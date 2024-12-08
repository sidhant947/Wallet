import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:wallet/models/wallet.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  Box<Identity>? dataBox;

  @override
  void initState() {
    super.initState();
    _openDataBox();
  }

  Future<void> _openDataBox() async {
    dataBox = await Hive.openBox<Identity>('identity');
    setState(() {});
  }

  void _removeData(BuildContext context, int index) {
    dataBox?.deleteAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identity Card Deleted'),
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      // ignore: avoid_print
      print('Text copied to clipboard!');
    }).catchError((e) {
      // ignore: avoid_print
      print('Error copying to clipboard: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (dataBox == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Icon(
            Icons.wallet,
            size: 30,
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
        ),
        body: const Center(child: Text("Loading")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              setState(() {});
            }
          },
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.fingerprint)),
      body: Column(
        children: [
          ValueListenableBuilder(
            valueListenable: dataBox!.listenable(),
            builder: (context, Box<Identity> box, _) {
              if (box.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Lottie.asset("assets/loading.json"),
                  ),
                );
              } else {
                return Expanded(
                  child: ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      var person_identity = box.getAt(index);
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Slidable(
                          key: ValueKey(index),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (BuildContext context) {
                                  _removeData(context, index);
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  alignment: Alignment.topLeft,
                                  margin: const EdgeInsets.all(10.0),
                                  child: Text(person_identity!.Identity_name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Bebas',
                                          fontSize: 28)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    copyToClipboard(
                                        person_identity.Identity_number);
                                  },
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    margin: const EdgeInsets.all(10.0),
                                    child: Text(
                                      person_identity.Identity_number,
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
                );
              }
            },
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
