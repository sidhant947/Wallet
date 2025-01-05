import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:wallet/models/db_helper.dart';

import '../models/dataentry.dart';

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
        forceMaterialTransparency: true,
        centerTitle: true,
        backgroundColor: Colors.black,
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
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        alignment: Alignment.center,
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
                                          alignment: Alignment.center,
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
