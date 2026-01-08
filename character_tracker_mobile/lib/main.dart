import 'package:flutter/material.dart';
import 'services/theme_service.dart';
import 'ui/character_list_page.dart';
import 'package:flutter/foundation.dart';

final themeService = ThemeService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeService.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CharacterTracker',
          themeMode: mode,
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: const CharacterListPage(),
        );
      },
    );
  }
}
