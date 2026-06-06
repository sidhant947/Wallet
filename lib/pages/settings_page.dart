// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/backup_service.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  void initState() {
    super.initState();
  }

  String _getThemeDisplayName(ThemePreference preference) {
    switch (preference) {
      case ThemePreference.light: return 'Light';
      case ThemePreference.dark: return 'Dark';
      case ThemePreference.system: return 'Follow System';
    }
  }

  String _getDefaultScreenName(int index) {
    switch (index) {
      case 0: return 'Payments';
      case 1: return 'Passes';
      default: return 'Payments';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _LiquidGlassSection(
            title: 'Startup & Layout',
            icon: Icons.rocket_launch_outlined,
            children: [
              _LiquidGlassTile(
                icon: Icons.shield_outlined,
                title: 'Authentication Screen',
                subtitle: 'Require biometrics when app starts',
                trailing: Switch(
                  value: startupProvider.showAuthenticationScreen,
                  onChanged: (_) {
                    startupProvider.toggleAuthenticationScreen();
                  },
                ),
              ),
              Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), height: 1),
              _LiquidGlassTile(
                icon: Icons.payments_outlined,
                title: 'Currency',
                subtitle: '${startupProvider.selectedCurrencyCode} (${startupProvider.selectedCurrencySymbol})',
                onTap: () => _showCurrencyDialog(context, startupProvider),
              ),
              Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), height: 1),
              if (!startupProvider.paymentsOnlyMode) ...[
                _LiquidGlassTile(
                  icon: Icons.home_filled,
                  title: 'Default Screen',
                  subtitle: _getDefaultScreenName(startupProvider.defaultScreenIndex),
                  onTap: () => _showDefaultScreenDialog(context, startupProvider),
                ),
                Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), height: 1),
              ],
              _LiquidGlassTile(
                icon: Icons.credit_card_rounded,
                title: 'Payments Only Mode',
                subtitle: 'Hide Passes screen',
                trailing: Switch(
                  value: startupProvider.paymentsOnlyMode,
                  onChanged: (_) {
                    startupProvider.togglePaymentsOnlyMode();
                  },
                ),
              ),
            ],
          ),

          _LiquidGlassSection(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            children: [
              _LiquidGlassTile(
                icon: Icons.brightness_6_outlined,
                title: 'App Theme',
                subtitle: _getThemeDisplayName(themeProvider.themePreference),
                onTap: () => _showThemeDialog(context, themeProvider),
              ),
              Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), height: 1),
              _LiquidGlassTile(
                icon: Icons.font_download_outlined,
                title: 'Use System Font',
                subtitle: 'Use the default system font',
                trailing: Switch(
                  value: themeProvider.useSystemFont,
                  onChanged: (_) => themeProvider.toggleFont(),
                ),
              ),
            ],
          ),

          _LiquidGlassSection(
            title: 'Data Management',
            icon: Icons.storage_outlined,
            children: [
              _LiquidGlassTile(
                icon: Icons.backup_outlined,
                title: 'Create Backup',
                subtitle: 'Save an encrypted copy of your data',
                onTap: () => _showBackupDialog(context, themeProvider),
              ),
              Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), height: 1),
              _LiquidGlassTile(
                icon: Icons.restore_outlined,
                title: 'Restore from Backup',
                subtitle: 'Replace current data from a backup file',
                onTap: () => _showRestoreDialog(context, themeProvider),
              ),
              Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), height: 1),
              _LiquidGlassTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete All Data',
                subtitle: 'Permanently erase all data from this device',
                onTap: () => _showDeleteAllDataDialog(context, themeProvider),
              ),
            ],
          ),

          _LiquidGlassSection(
            title: 'About',
            icon: Icons.info_outline_rounded,
            children: [
              _LiquidGlassTile(
                icon: Icons.gavel_outlined,
                title: 'Trademark Notice',
                subtitle: 'Card network logos are trademarks of their respective owners.',
                onTap: () => _showTrademarkNotice(context, isDark),
              ),
              Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), height: 1),
              _LiquidGlassTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Made with ❤️ by Sidhant',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTrademarkNotice(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: const Text('Trademark Fair Use Notice', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'The Visa, Mastercard, RuPay, American Express, and Discover logos displayed in this application are registered trademarks of their respective owners.\n\n'
            'These logos are used solely for identifying the card network. This usage constitutes nominative fair use.\n\n'
            'This application is not affiliated with, endorsed by, or sponsored by any of these companies.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, StartupSettingsProvider provider) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: const Text('Choose Currency', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: StartupSettingsProvider.majorCurrencies.length,
            itemBuilder: (context, index) {
              final currency = StartupSettingsProvider.majorCurrencies[index];
              return RadioListTile<String>(
                title: Text('${currency['name']} (${currency['symbol']})'),
                value: currency['code']!,
                groupValue: provider.selectedCurrencyCode,
                onChanged: (val) {
                  if (val != null) {
                    provider.setCurrency(val, currency['symbol']!);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDefaultScreenDialog(BuildContext context, StartupSettingsProvider provider) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: const Text('Default Screen', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption('Payments', 0, provider.defaultScreenIndex, (v) { provider.setDefaultScreen(v); Navigator.pop(context); }, isDark),
            _buildRadioOption('Passes', 1, provider.defaultScreenIndex, (v) { provider.setDefaultScreen(v); Navigator.pop(context); }, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, int value, int groupValue, Function(int) onChanged, bool isDark) {
    return RadioListTile<int>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (val) { if (val != null) onChanged(val); },
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: const Text('Choose Theme', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemePreference.values.map((p) => RadioListTile<ThemePreference>(
            title: Text(_getThemeDisplayName(p)),
            value: p,
            groupValue: themeProvider.themePreference,
            onChanged: (v) { if (v != null) { themeProvider.setThemePreference(v); Navigator.pop(context); } },
          )).toList(),
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (dialogContext) => _LiquidGlassPasswordDialog(
        title: 'Create Backup',
        content: 'Enter a strong password to encrypt your backup file.',
        buttonText: 'Create Backup',
        isDark: isDark,
        onConfirm: (password) async {
          try {
            final path = await BackupService.createBackup(password);
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
              if (path != null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Backup saved successfully!'), backgroundColor: Colors.green)
                );
              }
            }
          } catch (e) {
             if (dialogContext.mounted) {
               final errorMsg = e.toString().replaceFirst('Exception: ', '');
               ScaffoldMessenger.of(dialogContext).showSnackBar(
                 SnackBar(content: Text('Backup failed: $errorMsg'), backgroundColor: Colors.red)
               );
             }
          }
        },
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (dialogContext) => _LiquidGlassPasswordDialog(
        title: 'Restore Backup',
        content: 'Enter the password for the backup file. This will replace all current data.',
        buttonText: 'Restore',
        isDestructive: true,
        isDark: isDark,
        onConfirm: (password) async {
          try {
            await BackupService.restoreBackup(password);
            if (dialogContext.mounted) {
              context.read<WalletProvider>().fetchWallets();
              context.read<PassProvider>().fetchPasses();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Restored successfully!'), backgroundColor: Colors.green)
              );
            }
          } catch (e) {
             if (dialogContext.mounted) {
               final errorMsg = e.toString().replaceFirst('Exception: ', '');
               ScaffoldMessenger.of(dialogContext).showSnackBar(
                 SnackBar(content: Text('Restore failed: $errorMsg'), backgroundColor: Colors.red)
               );
             }
          }
        },
      ),
    );
  }

  void _showDeleteAllDataDialog(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: const Text('Delete All Data?'),
        content: const Text('This will permanently delete all wallets, passes, and images.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _performDeleteAllData(context);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAllData(BuildContext context) async {
    try {
      final wallets = await DatabaseHelper.instance.getWallets();
      for (var w in wallets) {
        if (w.id != null) {
          await DatabaseHelper.instance.deleteWallet(w.id!);
        }
      }
      
      final passes = await PassDatabaseHelper.instance.getAllPasses();
      for (var p in passes) {
        if (p.id != null) {
          await PassDatabaseHelper.instance.deletePass(p.id!);
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      if (await dir.exists()) {
        for (var f in dir.listSync()) {
          if (f is File && (f.path.endsWith('.enc') || f.path.endsWith('.png') || f.path.endsWith('.jpg'))) {
            await f.delete();
          }
        }
      }
      
      await const FlutterSecureStorage().deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wallet_aes_256_master_key_fallback');
      if (context.mounted) {
        context.read<WalletProvider>().fetchWallets();
        context.read<PassProvider>().fetchPasses();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data deleted.')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }
}

class _LiquidGlassSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  const _LiquidGlassSection({required this.title, this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final color = isDark ? Colors.white38 : Colors.black38;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Row(children: [if (icon != null) Icon(icon, size: 14, color: color), const SizedBox(width: 8), Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2))]),
        ),
        Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5), border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), width: 0.5)), child: Column(children: children)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LiquidGlassTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _LiquidGlassTile({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: textColor, size: 20)),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)) : null,
      trailing: trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white30 : Colors.black26) : null),
    );
  }
}

class _LiquidGlassPasswordDialog extends StatefulWidget {
  final String title;
  final String content;
  final String buttonText;
  final bool isDestructive;
  final bool isDark;
  final Future<void> Function(String) onConfirm;
  const _LiquidGlassPasswordDialog({required this.title, required this.content, required this.buttonText, this.isDestructive = false, required this.isDark, required this.onConfirm});

  @override
  State<_LiquidGlassPasswordDialog> createState() => _LiquidGlassPasswordDialogState();
}

class _LiquidGlassPasswordDialogState extends State<_LiquidGlassPasswordDialog> {
  late final TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDark ? const Color(0xFF0A0A0A) : Colors.white,
      title: Text(widget.title, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.content, style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async { 
            if (_passwordController.text.isEmpty) return;
            setState(() => _isLoading = true); 
            await widget.onConfirm(_passwordController.text); 
            if (mounted) setState(() => _isLoading = false); 
          },
          style: FilledButton.styleFrom(backgroundColor: widget.isDestructive ? Colors.red : (widget.isDark ? Colors.white : Colors.black)),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.buttonText),
        ),
      ],
    );
  }
}
