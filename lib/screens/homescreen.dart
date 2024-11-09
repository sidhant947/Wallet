import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'about.dart';
import 'data.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<Box<Map>> _openBox() async {
    return await Hive.openBox<Map>('dataBox');
  }

  void _removeData(BuildContext context, Box<Map> dataBox, int index) {
    dataBox.deleteAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Card Deleted')),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      print('Text copied to clipboard!');
    }).catchError((e) {
      print('Error copying to clipboard: $e');
    });
  }

  String formatCardNumber(String input) {
    StringBuffer result = StringBuffer();
    int count = 0;

    for (int i = 0; i < input.length; i++) {
      result.write(input[i]);
      count++;

      if (count == 4 && i != input.length - 1) {
        result.write(' - ');
        count = 0;
      }
    }

    return result.toString();
  }

  String formatExpiryNumber(String input) {
    StringBuffer result = StringBuffer();
    int count = 0;

    for (int i = 0; i < input.length; i++) {
      result.write(input[i]);
      count++;

      if (count == 2 && i != input.length - 1) {
        result.write(' / ');
        count = 0;
      }
    }

    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Icon(
          Icons.wallet,
          size: 34,
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutScreen()),
                );
              },
              icon: Icon(Icons.person))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                var result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DataEntryScreen()),
                );

                if (result != null) {
                  setState(() {});
                }
              },
              child: Text('Add Card'),
            ),
            SizedBox(height: 20),
            FutureBuilder<Box<Map>>(
              future: _openBox(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return Center(child: Text('No data found'));
                }

                Box<Map> dataBox = snapshot.data!;
                return Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: dataBox.listenable(),
                    builder: (context, Box<Map> box, _) {
                      if (box.isEmpty) {
                        return Center(
                            child: Text('Tap on Add Card to Save Cards'));
                      } else {
                        return ListView.builder(
                          itemCount: box.length,
                          itemBuilder: (context, index) {
                            var data = box.getAt(index) ?? {};
                            String displaynumber =
                                formatCardNumber(data["number"]);
                            String displayexpiry =
                                formatExpiryNumber(data["expiry"]);

                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Slidable(
                                key: ValueKey(index),
                                endActionPane: ActionPane(
                                  motion: ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (BuildContext context) {
                                        _removeData(context, dataBox, index);
                                      },
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.all(10.0),
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(300, 50),
                                          ),
                                          child: Text(
                                            data["name"],
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.all(10.0),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            copyToClipboard(data["number"]);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(300, 50),
                                          ),
                                          child: Text(displaynumber),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Container(
                                            margin: EdgeInsets.all(10.0),
                                            child: ElevatedButton(
                                              onPressed: () {},
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: Size(100, 50),
                                              ),
                                              child: Text(displayexpiry),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.all(10.0),
                                            child: ElevatedButton(
                                              onPressed: () {},
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: Size(100, 50),
                                              ),
                                              child: Text(data["cvv"]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
