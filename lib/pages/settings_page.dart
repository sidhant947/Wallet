// ignore_for_file: deprecated_member_use, use_build_context_synchronously

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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _getThemeDisplayName(ThemePreference preference) {
    switch (preference) {
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
      case ThemePreference.system:
        return 'Follow System';
    }
  }

  String _getDefaultScreenName(int index) {
    switch (index) {
      case 0:
        return 'Payments';
      case 1:
        return 'Loyalty';
      case 2:
        return 'Identity';
      default:
        return 'Payments';
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
          // --- Startup & Layout Settings Section ---
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
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              if (!startupProvider.hideIdentityAndLoyalty) ...[
                _LiquidGlassTile(
                  icon: Icons.home_filled,
                  title: 'Default Screen',
                  subtitle: _getDefaultScreenName(
                    startupProvider.defaultScreenIndex,
                  ),
                  onTap: () =>
                      _showDefaultScreenDialog(context, startupProvider),
                ),
                Divider(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE8E8E8),
                  height: 1,
                ),
              ],
              _LiquidGlassTile(
                icon: Icons.credit_card_rounded,
                title: 'Payments Only Mode',
                subtitle: 'Hide Loyalty and Identity screens',
                trailing: Switch(
                  value: startupProvider.hideIdentityAndLoyalty,
                  onChanged: (_) {
                    startupProvider.toggleHideIdentityAndLoyalty();
                  },
                ),
              ),
            ],
          ),

          // --- Theme Settings Section ---
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
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.font_download_outlined,
                title: 'Use System Font',
                subtitle: 'Use the default system font',
                trailing: Switch(
                  value: themeProvider.useSystemFont,
                  onChanged: (_) {
                    themeProvider.toggleFont();
                  },
                ),
              ),
            ],
          ),

          // --- Backup & Restore Section ---
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
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.restore_outlined,
                title: 'Restore from Backup',
                subtitle: 'Replace current data from a backup file',
                onTap: () {
                  final walletProvider = context.read<WalletProvider>();
                  _showRestoreDialog(context, themeProvider, walletProvider);
                },
              ),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete All Data',
                subtitle: 'Permanently erase all data from this device',
                onTap: () => _showDeleteAllDataDialog(context, themeProvider),
              ),
            ],
          ),

          // --- About Section ---
          _LiquidGlassSection(
            title: 'About',
            icon: Icons.info_outline_rounded,
            children: [
              _LiquidGlassTile(
                icon: Icons.gavel_outlined,
                title: 'Trademark Notice',
                subtitle:
                    'Card network logos (Visa, Mastercard, RuPay, Amex, Discover) are trademarks of their respective owners. Used for identification purposes only under nominative fair use. No affiliation or endorsement is implied.',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark
                          ? const Color(0xFF0A0A0A)
                          : Colors.white,
                      title: Text(
                        'Trademark Fair Use Notice',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Text(
                          'The Visa, Mastercard, RuPay, American Express, and Discover logos displayed in this application are registered trademarks of their respective owners:\n\n'
                          '• Visa Inc.\n'
                          '• Mastercard International\n'
                          '• National Payments Corporation of India (RuPay)\n'
                          '• American Express Company\n'
                          '• Discover Financial Services\n\n'
                          'These logos are used solely for the purpose of identifying the card network associated with a user\'s payment card. This usage constitutes nominative fair use under trademark law.\n\n'
                          'This application is not affiliated with, endorsed by, or sponsored by any of these companies. No trademark license has been granted beyond the limited use described above.\n\n'
                          'All other trademarks and copyrights are the property of their respective owners.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Made with ❤️ by Sidhant',
                subtitle: 'Version 1.0.0',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDefaultScreenDialog(
    BuildContext context,
    StartupSettingsProvider provider,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(
          'Default Screen',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption(
              context,
              'Payments',
              0,
              provider.defaultScreenIndex,
              (val) {
                provider.setDefaultScreen(val);
                Navigator.pop(context);
              },
              isDark,
            ),
            _buildRadioOption(
              context,
              'Loyalty',
              1,
              provider.defaultScreenIndex,
              (val) {
                provider.setDefaultScreen(val);
                Navigator.pop(context);
              },
              isDark,
            ),
            _buildRadioOption(
              context,
              'Identity',
              2,
              provider.defaultScreenIndex,
              (val) {
                provider.setDefaultScreen(val);
                Navigator.pop(context);
              },
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext context,
    String label,
    int value,
    int groupValue,
    Function(int) onChanged,
    bool isDark,
  ) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0))
            : Colors.transparent,
      ),
      child: RadioListTile<int>(
        title: Text(
          label,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        value: value,
        groupValue: groupValue,
        activeColor: isDark ? Colors.white : Colors.black,
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(
          'Choose Theme',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemePreference.values.map((preference) {
            final isSelected = themeProvider.themePreference == preference;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0F0F0))
                    : Colors.transparent,
              ),
              child: RadioListTile<ThemePreference>(
                title: Text(
                  _getThemeDisplayName(preference),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                value: preference,
                groupValue: themeProvider.themePreference,
                activeColor: isDark ? Colors.white : Colors.black,
                onChanged: (ThemePreference? value) {
                  if (value != null) {
                    themeProvider.setThemePreference(value);
                    Navigator.pop(context);
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, ThemeProvider themeProvider) {
    final passwordController = TextEditingController();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (context) => _LiquidGlassPasswordDialog(
        title: 'Create Backup',
        content:
            'Enter a strong password to encrypt your backup file. Do not forget this password.',
        buttonText: 'Create Backup',
        passwordController: passwordController,
        isDark: isDark,
        onConfirm: () async {
          if (passwordController.text.isEmpty) return;
          try {
            final backupPath = await BackupService.createBackup(
              passwordController.text,
            );

            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Backup created successfully! Saved to: $backupPath',
                ),
                backgroundColor: Colors.green.shade600,
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Backup failed: $e'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        },
      ),
    ).then((_) => passwordController.dispose());
  }

  void _showRestoreDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    WalletProvider walletProvider,
  ) {
    final passwordController = TextEditingController();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (context) => _LiquidGlassPasswordDialog(
        title: 'Restore Backup',
        content:
            'This will replace all current data. Enter the password for the backup file.',
        buttonText: 'Restore & Overwrite',
        isDestructive: true,
        passwordController: passwordController,
        isDark: isDark,
        onConfirm: () async {
          if (passwordController.text.isEmpty) return;
          try {
            await BackupService.restoreBackup(passwordController.text);
            await context.read<WalletProvider>().fetchWallets();
            await context.read<LoyaltyProvider>().fetchLoyalties();
            await context.read<IdentityProvider>().fetchIdentities();

            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: const Text('Backup restored successfully!'),
                backgroundColor: Colors.green.shade600,
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Restore failed: $e'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        },
      ),
    ).then((_) => passwordController.dispose());
  }

  void _showDeleteAllDataDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.red.shade600,
          size: 48,
        ),
        title: Text(
          'Delete All Data?',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will permanently delete ALL wallets, loyalty cards, identity cards, and associated images. This action cannot be undone.\n\n'
          'It is recommended to create a backup first.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        // Second confirmation
        final doubleConfirm = await showDialog<bool>(
          context: context,
          barrierColor: isDark ? Colors.black54 : Colors.black26,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            title: Text(
              'Final Confirmation',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you absolutely sure? Type "DELETE" to confirm.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Delete'),
              ),
            ],
          ),
        );

        if (doubleConfirm == true) {
          await _performDeleteAllData(context, themeProvider);
        }
      }
    });
  }

  Future<void> _performDeleteAllData(
    BuildContext context,
    ThemeProvider themeProvider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Delete all wallets
      final wallets = await DatabaseHelper.instance.getWallets();
      for (final wallet in wallets) {
        if (wallet.id != null) {
          await DatabaseHelper.instance.deleteWallet(wallet.id!);
        }
      }

      // Delete all identities
      final identities = await IdentityDatabaseHelper.instance
          .getAllIdentities();
      for (final identity in identities) {
        if (identity.id != null) {
          await IdentityDatabaseHelper.instance.deleteIdentity(identity.id!);
        }
      }

      // Delete all loyalties
      final loyalties = await LoyaltyDatabaseHelper.instance.getAllLoyalties();
      for (final loyalty in loyalties) {
        if (loyalty.id != null) {
          await LoyaltyDatabaseHelper.instance.deleteLoyalty(loyalty.id!);
        }
      }

      // Delete all image files from the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      if (await dir.exists()) {
        final files = dir.listSync();
        for (final file in files) {
          if (file is File) {
            final path = file.path;
            // Delete image files (but NOT database files)
            if (path.endsWith('.jpg') ||
                path.endsWith('.jpeg') ||
                path.endsWith('.png') ||
                path.endsWith('.webp') ||
                path.endsWith('.bmp') ||
                path.endsWith('.enc')) {
              await file.delete();
            }
          }
        }
      }

      // Clear secure storage (encryption key)
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();

      // Refresh providers
      await context.read<WalletProvider>().fetchWallets();
      await context.read<LoyaltyProvider>().fetchLoyalties();
      await context.read<IdentityProvider>().fetchIdentities();

      messenger.showSnackBar(
        SnackBar(
          content: const Text('All data has been permanently deleted'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete all data: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}

// --- LIQUID GLASS SECTION WIDGET ---
class _LiquidGlassSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const _LiquidGlassSection({
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
              width: 0.5,
            ),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// --- LIQUID GLASS TILE WIDGET ---
class _LiquidGlassTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _LiquidGlassTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: textColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 13,
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white30 : Colors.black26,
                )
              : null),
    );
  }
}

// --- LIQUID GLASS PASSWORD DIALOG ---
class _LiquidGlassPasswordDialog extends StatefulWidget {
  final String title;
  final String content;
  final String buttonText;
  final bool isDestructive;
  final TextEditingController passwordController;
  final bool isDark;
  final Future<void> Function() onConfirm;

  const _LiquidGlassPasswordDialog({
    required this.title,
    required this.content,
    required this.buttonText,
    this.isDestructive = false,
    required this.passwordController,
    required this.isDark,
    required this.onConfirm,
  });

  @override
  State<_LiquidGlassPasswordDialog> createState() =>
      _LiquidGlassPasswordDialogState();
}

class _LiquidGlassPasswordDialogState
    extends State<_LiquidGlassPasswordDialog> {
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleConfirm() async {
    setState(() => _isLoading = true);
    await widget.onConfirm();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black;

    return AlertDialog(
      backgroundColor: widget.isDark ? const Color(0xFF0A0A0A) : Colors.white,
      title: Text(
        widget.title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.content,
            style: TextStyle(
              color: widget.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: widget.isDark
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFF5F5F5),
            ),
            child: TextField(
              controller: widget.passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: widget.isDark ? Colors.white54 : Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: widget.isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: widget.isDestructive
                ? Colors.red.shade600
                : (widget.isDark ? Colors.white : Colors.black),
            foregroundColor: widget.isDestructive
                ? Colors.white
                : (widget.isDark ? Colors.black : Colors.white),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.isDestructive
                        ? Colors.white
                        : (widget.isDark ? Colors.black : Colors.white),
                  ),
                )
              : Text(widget.buttonText),
        ),
      ],
    );
  }
}
