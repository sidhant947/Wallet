import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import '../models/dataentry.dart';
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
