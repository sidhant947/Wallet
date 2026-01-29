import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/dataentry.dart';
import 'package:wallet/models/theme_provider.dart';

import 'package:wallet/models/startup_settings_provider.dart';

class AddCardScreen extends StatefulWidget {
  final int initialTabIndex;

  const AddCardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _hideIdentityAndLoyalty = false;

  @override
  void initState() {
    super.initState();
    _hideIdentityAndLoyalty = context
        .read<StartupSettingsProvider>()
        .hideIdentityAndLoyalty;

    if (!_hideIdentityAndLoyalty) {
      _tabController = TabController(
        length: 3,
        vsync: this,
        initialIndex: widget.initialTabIndex,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Card'),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        bottom: _hideIdentityAndLoyalty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF5F5F5),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: isDark ? Colors.black : Colors.white,
                    unselectedLabelColor: isDark
                        ? Colors.white54
                        : Colors.black54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      _buildTab(Icons.credit_card_rounded, 'Credit/Debit'),
                      _buildTab(Icons.shopping_basket_rounded, 'Loyalty'),
                      _buildTab(Icons.fingerprint_rounded, 'Identity'),
                    ],
                  ),
                ),
              ),
      ),
      body: _hideIdentityAndLoyalty
          ? const CreditCardEntryForm()
          : TabBarView(
              controller: _tabController,
              children: const [
                CreditCardEntryForm(),
                BarcodeCardEntryForm(cardType: BarcodeCardType.loyalty),
                BarcodeCardEntryForm(cardType: BarcodeCardType.identity),
              ],
            ),
    );
  }

  Widget _buildTab(IconData icon, String text) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
