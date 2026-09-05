import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/controller_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProviderScope(child: BotControllerApp()));
}

class BotControllerApp extends StatelessWidget {
  const BotControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bot Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ControllerTheme.bezel,
        colorScheme: ColorScheme.dark(
          surface: ControllerTheme.shellBg,
          primary: ControllerTheme.ringActive,
        ),
      ),
      home: const ControllerScreen(),
    );
  }
}
