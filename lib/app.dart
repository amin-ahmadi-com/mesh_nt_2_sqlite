import 'package:flutter/material.dart';

import 'definitions.dart';
import 'home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "$applicationName v$applicationVersion",
      theme: appTheme,
      home: const HomePage(),
    );
  }
}
