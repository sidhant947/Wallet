import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/pkpass_service.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'package:wallet/widgets/credit_card_entry_form.dart';
import 'package:wallet/widgets/barcode_card_entry_form.dart';
import 'package:wallet/widgets/identity_card_entry_form.dart';

class AddCardScreen extends StatefulWidget {
  final int initialTabIndex;

  const AddCardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  Future<void> _importPkpass() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pkpass'],
      );

      if (result != null && result.files.single.path != null) {
        final pass = await PkpassService.instance.parsePkpass(
          result.files.single.path!,
        );
        if (pass != null) {
          if (mounted) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Pass'),
                content: Text(
                  'Do you want to import "${pass.organizationName}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Import'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await PassDatabaseHelper.instance.insertPass(pass);
              AutoBackupService.triggerBackup();
              if (mounted) {
                context.read<PassProvider>().fetchPasses();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pass imported successfully!')),
                );
                Navigator.pop(context, true);
              }
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to parse .pkpass file.')),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import pass. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final startupProvider = Provider.of<StartupSettingsProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    final int effectiveIndex = startupProvider.paymentsOnlyMode ? 0 : widget.initialTabIndex;

    Widget form;

    switch (effectiveIndex) {
      case 1:
        form = BarcodeCardEntryForm();
        break;
      case 2:
        form = IdentityCardEntryForm();
        break;
      case 0:
      default:
        form = CreditCardEntryForm();
        break;
    }

    return Scaffold(
      appBar: AppBar(
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
        actions: [
          if (effectiveIndex == 1)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                icon: Icon(
                  Icons.file_download_outlined,
                  color: textColor,
                  size: 18,
                ),
                label: Text(
                  'Import pkpass',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: _importPkpass,
              ),
            ),
        ],
      ),
      body: form,
    );
  }
}
