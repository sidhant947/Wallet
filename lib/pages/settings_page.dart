// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/backup_service.dart';
import 'package:wallet/models/provider_helper.dart';

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
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
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
          // --- Startup Settings Section ---
          _LiquidGlassSection(
            title: 'Startup',
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
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
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
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
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
            ],
          ),

          // --- About Section ---
          _LiquidGlassSection(
            title: 'Support',
            icon: Icons.favorite_outline_rounded,
            children: [
              _LiquidGlassTile(
                icon: Icons.code_rounded,
                title: 'Support',
                subtitle: 'Support for App Store Release',
                onTap: () {
                  launchUrl(
                    Uri.parse('https://github.com/sponsors/sidhant947'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
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
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: themeProvider.themePreference == preference
                      ? (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05))
                      : Colors.transparent,
                  border: Border.all(
                    color: themeProvider.themePreference == preference
                        ? (isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1))
                        : Colors.transparent,
                  ),
                ),
                child: RadioListTile<ThemePreference>(
                  title: Text(
                    _getThemeDisplayName(preference),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
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
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: _LiquidGlassPasswordDialog(
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
      ),
    );
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: _LiquidGlassPasswordDialog(
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
      ),
    );
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor.withOpacity(0.4)),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor.withOpacity(0.4),
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
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.03),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(children: children),
            ),
          ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: textColor.withOpacity(0.8), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: textColor.withOpacity(0.3),
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
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: widget.isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.03),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: TextField(
              controller: widget.passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: textColor.withOpacity(0.5)),
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
                    color: textColor.withOpacity(0.5),
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
            style: TextStyle(color: textColor.withOpacity(0.5)),
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
