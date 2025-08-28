import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: themeProvider.getTextStyle(fontSize: 20),
        ),
      ),
      body: ListView(
        children: [
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
        ],
      ),
    );
  }
}
