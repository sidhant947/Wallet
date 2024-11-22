import 'package:flutter/material.dart';

class BankCards extends StatefulWidget {
  const BankCards({super.key});

  @override
  State<BankCards> createState() => _BankCardsState();
}

class _BankCardsState extends State<BankCards>
    with SingleTickerProviderStateMixin {
  List<Widget> tabs = [
    const Center(child: Text('Beginner cards')),
    const Center(child: Text('Beginner cards')),
    const Center(child: Text('Beginner cards')),
    const Center(child: Text('Beginner cards')),
    const Center(child: Text('Beginner cards')),
    const Center(child: Text('Beginner cards')),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 3 tabs
  }

  late TabController _tabController;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: const Text(
          'Cards',
          style: TextStyle(color: Colors.deepPurpleAccent),
        ),
        bottom: TabBar(
          labelColor: Colors.deepPurpleAccent,
          isScrollable: true,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Beginers'),
            Tab(text: 'LTF'),
            Tab(text: 'Premium'),
            Tab(text: 'Travel'),
            Tab(text: 'Fuel'),
            Tab(text: 'Groceries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs,
      ),
    );
  }
}
