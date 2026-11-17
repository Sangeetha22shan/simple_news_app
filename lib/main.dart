
import 'package:flutter/material.dart';

import 'features/news/views/news_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SimpleNewsApp());
}

class SimpleNewsApp extends StatelessWidget {
  const SimpleNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple News App',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: ThemeMode.system,

      home: const NewsListScreen(),
    );
  }
}
