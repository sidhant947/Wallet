import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/widgets/credit_card_entry_form.dart';
import 'package:wallet/widgets/barcode_card_entry_form.dart';
import 'package:wallet/widgets/identity_card_entry_form.dart';

class AddCardScreen extends StatelessWidget {
  final int initialTabIndex;

  const AddCardScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final startupProvider = Provider.of<StartupSettingsProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    // Decide which form to show based on the index passed from HomeScreen
    // Index 0: Payments, Index 1: Passes, Index 2: Identity
    final int effectiveIndex = startupProvider.paymentsOnlyMode ? 0 : initialTabIndex;

    String title;
    Widget form;

    switch (effectiveIndex) {
      case 1:
        title = 'Add New Pass';
        form = BarcodeCardEntryForm();
        break;
      case 2:
        title = 'Add Identity Card';
        form = IdentityCardEntryForm();
        break;
      case 0:
      default:
        title = 'Add Payment Card';
        form = CreditCardEntryForm();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
      ),
      body: form,
    );
  }
}
