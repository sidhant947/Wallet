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

class _AddCardScreenState extends State<AddCardScreen> {
  int _currentIndex = 0;
  bool _hideIdentityAndLoyalty = false;

  @override
  void initState() {
    super.initState();
    _hideIdentityAndLoyalty = context
        .read<StartupSettingsProvider>()
        .hideIdentityAndLoyalty;
    _currentIndex = widget.initialTabIndex;
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
                  child: Row(
                    children: [
                      _buildTabItem(0, Icons.credit_card_rounded, 'Payments', isDark),
                      _buildTabItem(1, Icons.shopping_basket_rounded, 'Loyalty', isDark),
                      _buildTabItem(2, Icons.fingerprint_rounded, 'Identity', isDark),
                    ],
                  ),
                ),
              ),
      ),
      body: _hideIdentityAndLoyalty
          ? const CreditCardEntryForm()
          : IndexedStack(
              index: _currentIndex,
              children: const [
                CreditCardEntryForm(),
                BarcodeCardEntryForm(cardType: BarcodeCardType.loyalty),
                BarcodeCardEntryForm(cardType: BarcodeCardType.identity),
              ],
            ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String text, bool isDark) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
