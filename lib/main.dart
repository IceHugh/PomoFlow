import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'pomodoro_timer.dart';
import 'timer_service.dart';
import 'package:home_widget/home_widget.dart';
import 'services/tray_service.dart';

// 从编译时参数获取版本号
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 600),
      minimumSize: Size(400, 600),
      maximumSize: Size(400, 600),
      center: true,
      title: 'PomoFlow',
      backgroundColor: CupertinoColors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }

  // Register Background Callback early
  HomeWidget.registerInteractivityCallback(backgroundCallback);

  runApp(
    ChangeNotifierProvider(
      create: (context) => TimerService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    TrayService().init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
      await windowManager.setSkipTaskbar(true);
    }
  }

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