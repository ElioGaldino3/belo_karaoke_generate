import 'package:belo_karaoke_generate/pages/home_page.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureWindow();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

Future<void> _configureWindow() async {
  const windowSize = Size(776, 268);
  await DesktopWindow.setWindowSize(windowSize);
  await DesktopWindow.setMinWindowSize(windowSize);
  await DesktopWindow.setMaxWindowSize(windowSize);
}
