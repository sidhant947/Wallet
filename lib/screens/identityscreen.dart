import 'package:barcode_widget/barcode_widget.dart';
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
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          identities == null
              ? Center(child: Lottie.asset("assets/loading.json"))
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
                                child: GestureDetector(
                                  onTap: () {
                                    copyToClipboard(identity.identityNumber);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.deepPurpleAccent,
                                          Colors.deepPurple
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        tileMode: TileMode
                                            .repeated, // This repeats the gradient
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Divider(
                                          color: Colors.white,
                                          thickness: 5,
                                        ),
                                        Container(
                                          alignment: Alignment.topRight,
                                          margin: const EdgeInsets.all(10.0),
                                          child: Text(identity.identityName,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Bebas',
                                                  fontSize: 28)),
                                        ),
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.white,
                                          child:
                                              Lottie.asset("assets/card.json"),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.all(10.0),
                                              child: Text(
                                                identity.identityNumber,
                                                style: const TextStyle(
                                                    letterSpacing: 1,
                                                    fontSize: 20),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            identityBarCode(
                                                                qrnumber: identity
                                                                    .identityNumber)));
                                              },
                                              child: Container(
                                                  margin: const EdgeInsets.all(
                                                      10.0),
                                                  child: Icon(
                                                    Icons.qr_code,
                                                    size: 30,
                                                  )),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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

class identityBarCode extends StatelessWidget {
  const identityBarCode({super.key, required this.qrnumber});
  final String qrnumber;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BarCode"),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: Center(
        child: SizedBox(
          height: 300,
          width: 300,
          child: PageView(
            scrollDirection: Axis.horizontal,
            children: [
              BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: qrnumber, // Content
                width: 200,
                height: 200,
                color: Colors.white,
              ),
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: qrnumber, // Content
                width: 200,
                height: 200,
                color: Colors.white,
              ),
              BarcodeWidget(
                barcode: Barcode.code39(),
                data: qrnumber, // Content
                width: 200,
                height: 200,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
