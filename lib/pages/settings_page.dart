// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/backup_service.dart';
import 'package:wallet/models/provider_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Helper to get a user-friendly name for each theme option
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Startup Settings Section ---
          _SettingsSection(
            title: 'Startup',
            children: [
              _SettingsTile(
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
              _SettingsTile(
                icon: Icons.web_asset_outlined,
                title: 'Default Screen',
                subtitle: startupProvider.getScreenDisplayName(
                  startupProvider.defaultScreen,
                ),
                onTap: () => _showDefaultScreenDialog(
                  context,
                  themeProvider,
                  startupProvider,
                ),
              ),
            ],
          ),

          // --- Theme Settings Section (MODIFIED) ---
          _SettingsSection(
            title: 'Appearance',
            children: [
              // This tile replaces the old Dark Mode switch
              _SettingsTile(
                icon: Icons.brightness_6_outlined,
                title: 'App Theme',
                subtitle: _getThemeDisplayName(themeProvider.themePreference),
                onTap: () => _showThemeDialog(context, themeProvider),
              ),
              _SettingsTile(
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
          _SettingsSection(
            title: 'Data Management',
            children: [
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Create Backup',
                subtitle: 'Save an encrypted copy of your data',
                onTap: () => _showBackupDialog(context, themeProvider),
              ),
              _SettingsTile(
                icon: Icons.restore_outlined,
                title: 'Restore from Backup',
                subtitle: 'Replace current data from a backup file',
                onTap: () {
                  final walletProvider = context.read<WalletProvider>();
                  _showRestoreDialog(context, themeProvider, walletProvider);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method to show the theme selection dialog
  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemePreference.values.map((preference) {
            return RadioListTile<ThemePreference>(
              title: Text(_getThemeDisplayName(preference)),
              value: preference,
              // FIX: Ignoring linter warning for deprecated member
              // ignore: deprecated_member_use
              groupValue: themeProvider.themePreference,
              // FIX: Ignoring linter warning for deprecated member
              // ignore: deprecated_member_use
              onChanged: (ThemePreference? value) {
                if (value != null) {
                  themeProvider.setThemePreference(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDefaultScreenDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    StartupSettingsProvider startupProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Default Screen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: StartupScreen.values.map((screen) {
            return RadioListTile<StartupScreen>(
              title: Text(startupProvider.getScreenDisplayName(screen)),
              value: screen,
              // FIX: Ignoring linter warning for deprecated member
              // ignore: deprecated_member_use
              groupValue: startupProvider.defaultScreen,
              // FIX: Ignoring linter warning for deprecated member
              // ignore: deprecated_member_use
              onChanged: (StartupScreen? value) {
                if (value != null) {
                  startupProvider.setDefaultScreen(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, ThemeProvider themeProvider) {
    final passwordController = TextEditingController();
    // FIX: Capture navigator and messenger before the dialog is shown
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => _PasswordDialog(
        title: 'Create Backup',
        content:
            'Enter a strong password to encrypt your backup file. Do not forget this password.',
        buttonText: 'Create Backup',
        passwordController: passwordController,
        onConfirm: () async {
          if (passwordController.text.isEmpty) return;
          try {
            final backupPath = await BackupService.createBackup(
              passwordController.text,
            );

            navigator.pop(); // Close dialog on success
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Backup created successfully! Saved to: $backupPath',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Backup failed: $e'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }

  void _showRestoreDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    WalletProvider walletProvider,
  ) {
    final passwordController = TextEditingController();
    // FIX: Capture navigator and messenger before the dialog is shown
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => _PasswordDialog(
        title: 'Restore Backup',
        content:
            'This will replace all current data. Enter the password for the backup file.',
        buttonText: 'Restore & Overwrite',
        isDestructive: true,
        passwordController: passwordController,
        onConfirm: () async {
          if (passwordController.text.isEmpty) return;
          try {
            await BackupService.restoreBackup(passwordController.text);
            await walletProvider.fetchWallets(); // Refresh data

            navigator.pop(); // Close dialog on success
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Backup restored successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Restore failed: $e'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER WIDGETS FOR SETTINGS UI
// -----------------------------------------------------------------------------

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  final String title;
  final String content;
  final String buttonText;
  final bool isDestructive;
  final TextEditingController passwordController;
  final Future<void> Function() onConfirm;

  const _PasswordDialog({
    required this.title,
    required this.content,
    required this.buttonText,
    this.isDestructive = false,
    required this.passwordController,
    required this.onConfirm,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  bool _isLoading = false;

  void _handleConfirm() async {
    setState(() => _isLoading = true);
    await widget.onConfirm();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.content),
          const SizedBox(height: 16),
          TextField(
            controller: widget.passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: widget.isDestructive
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.buttonText),
        ),
      ],
    );
  }
}
