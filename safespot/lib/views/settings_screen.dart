import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controllers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),

      body: ListView(
        children: [

          SwitchListTile(
            title: const Text("Dark Mode"),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("Licenses"),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: "SafeSpot",
              );
            },
          ),

        ],
      ),
    );
  }
}