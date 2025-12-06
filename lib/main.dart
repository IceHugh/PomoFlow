import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'pomodoro_timer.dart';
import 'timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must check if platform supports window_manager (desktop)
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 600),
      minimumSize: Size(400, 600),
      maximumSize: Size(400, 600), // Fix size
      center: true,
      title: 'PomoFlow',
      backgroundColor: CupertinoColors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // Custom look
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => TimerService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        Brightness? brightness;
        if (timerService.themeMode == 'dark') {
          brightness = Brightness.dark;
        } else if (timerService.themeMode == 'light') {
          brightness = Brightness.light;
        } else {
          // System default
          brightness = null; 
        }

        return CupertinoApp(
          title: 'PomoFlow',
          theme: CupertinoThemeData(
            primaryColor: CupertinoColors.activeBlue,
            brightness: brightness, 
            scaffoldBackgroundColor: brightness == Brightness.dark 
                ? CupertinoColors.black 
                : CupertinoColors.systemBackground,
          ),
          home: const PomodoroTimerPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}