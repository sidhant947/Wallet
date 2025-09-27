import 'package:flutter/material.dart';
import 'package:wallet/models/dataentry.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Card'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card), text: 'Credit/Debit'),
            Tab(icon: Icon(Icons.shopping_basket_outlined), text: 'Loyalty'),
            Tab(icon: Icon(Icons.fingerprint), text: 'Identity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // These are the refactored form widgets from dataentry.dart
          CreditCardEntryForm(),
          BarcodeCardEntryForm(cardType: BarcodeCardType.loyalty),
          BarcodeCardEntryForm(cardType: BarcodeCardType.identity),
        ],
      ),
    );
  }
}
