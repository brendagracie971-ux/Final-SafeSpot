import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_provider.dart';
//import '../views/home_screen.dart';
import '../views/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeSpot',
      themeMode: themeProvider.themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.red,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
      ),

      home: const SplashScreen(),
    );
  }
}