import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/backup_service.dart';
import 'package:wallet/models/provider_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: themeProvider.getTextStyle(fontSize: 20),
        ),
      ),
      body: ListView(
        children: [
          // Startup Settings Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Startup Settings',
              style: themeProvider.getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SwitchListTile(
            title: Text(
              'Show Authentication Screen',
              style: themeProvider.getTextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Require authentication when app starts',
              style: themeProvider.getTextStyle(
                fontSize: 14,
                color: themeProvider.secondaryColor,
              ),
            ),
            value: startupProvider.showAuthenticationScreen,
            activeThumbColor: themeProvider.accentColor,
            onChanged: (value) {
              startupProvider.toggleAuthenticationScreen();
            },
          ),

          ListTile(
            title: Text(
              'Default Screen',
              style: themeProvider.getTextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Choose which screen to show after startup: ${startupProvider.getScreenDisplayName(startupProvider.defaultScreen)}',
              style: themeProvider.getTextStyle(
                fontSize: 14,
                color: themeProvider.secondaryColor,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: themeProvider.secondaryColor,
              size: 16,
            ),
            onTap: () => _showDefaultScreenDialog(
              context,
              themeProvider,
              startupProvider,
            ),
          ),

          // Divider
          Divider(color: themeProvider.borderColor),

          // Theme Settings Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Theme Settings',
              style: themeProvider.getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: themeProvider.getTextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Toggle between light and dark themes',
              style: themeProvider.getTextStyle(
                fontSize: 14,
                color: themeProvider.secondaryColor,
              ),
            ),
            value: themeProvider.isDarkMode,
            activeThumbColor: themeProvider.accentColor,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          SwitchListTile(
            title: Text(
              'Use System Font',
              style: themeProvider.getTextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Use system default font instead of custom font',
              style: themeProvider.getTextStyle(
                fontSize: 14,
                color: themeProvider.secondaryColor,
              ),
            ),
            value: themeProvider.useSystemFont,
            activeThumbColor: themeProvider.accentColor,
            onChanged: (value) {
              themeProvider.toggleFont();
            },
          ),

          // Divider
          Divider(color: themeProvider.borderColor),

          // Backup & Restore Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Backup & Restore',
              style: themeProvider.getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.backup, color: themeProvider.accentColor),
            title: Text(
              'Create Backup',
              style: themeProvider.getTextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Export all your data to an encrypted backup file',
              style: themeProvider.getTextStyle(
                fontSize: 14,
                color: themeProvider.secondaryColor,
              ),
            ),
            onTap: () => _showBackupDialog(context, themeProvider),
          ),

          ListTile(
            leading: Icon(Icons.restore, color: themeProvider.accentColor),
            title: Text(
              'Restore Backup',
              style: themeProvider.getTextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Import data from an encrypted backup file',
              style: themeProvider.getTextStyle(
                fontSize: 14,
                color: themeProvider.secondaryColor,
              ),
            ),
            onTap: () =>
                _showRestoreDialog(context, themeProvider, walletProvider),
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
        backgroundColor: themeProvider.backgroundColor,
        title: Text(
          'Choose Default Screen',
          style: themeProvider.getTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: StartupScreen.values.map((screen) {
            return ListTile(
              title: Text(
                startupProvider.getScreenDisplayName(screen),
                style: themeProvider.getTextStyle(fontSize: 16),
              ),
              leading: Radio<StartupScreen>(
                value: screen,
                groupValue: startupProvider.defaultScreen,
                activeColor: themeProvider.accentColor,
                onChanged: (StartupScreen? value) {
                  if (value != null) {
                    startupProvider.setDefaultScreen(value);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                startupProvider.setDefaultScreen(screen);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: themeProvider.getTextStyle(
                fontSize: 14,
                color: themeProvider.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, ThemeProvider themeProvider) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: themeProvider.backgroundColor,
          title: Text(
            'Create Backup',
            style: themeProvider.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a password to encrypt your backup:',
                style: themeProvider.getTextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: themeProvider.getTextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Encryption Password',
                  labelStyle: themeProvider.getTextStyle(
                    fontSize: 14,
                    color: themeProvider.secondaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.borderColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: themeProvider.getTextStyle(
                  fontSize: 14,
                  color: themeProvider.secondaryColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a password'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final backupPath = await BackupService.createBackup(
                          passwordController.text,
                        );
                        Navigator.pop(context);

                        if (backupPath != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Backup created successfully!\nSaved to: $backupPath',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Backup failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.accentColor,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Create Backup',
                      style: themeProvider.getTextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
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
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: themeProvider.backgroundColor,
          title: Text(
            'Restore Backup',
            style: themeProvider.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This will replace all current data with the backup data. Enter the password used to encrypt the backup:',
                style: themeProvider.getTextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: themeProvider.getTextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Backup Password',
                  labelStyle: themeProvider.getTextStyle(
                    fontSize: 14,
                    color: themeProvider.secondaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.borderColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: themeProvider.getTextStyle(
                  fontSize: 14,
                  color: themeProvider.secondaryColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter the backup password'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        await BackupService.restoreBackup(
                          passwordController.text,
                        );
                        await walletProvider
                            .fetchWallets(); // Refresh the wallet list
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Backup restored successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Restore failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Restore Backup',
                      style: themeProvider.getTextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
