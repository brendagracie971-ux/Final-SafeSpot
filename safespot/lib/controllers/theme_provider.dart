import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = true;

  ThemeMode get themeMode =>
      isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme(bool value) {
    isDarkMode = value;
    notifyListeners();
  }
}