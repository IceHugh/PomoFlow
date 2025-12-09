import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();

  factory TrayService() {
    return _instance;
  }

  TrayService._internal();

  Future<void> init() async {
    if (Platform.isAndroid || Platform.isIOS) return;
    await trayManager.destroy(); // Cleanup any existing icon (helper for hot restart)
    
    // Must set icon first, then title will show next to it
    String iconPath;
    if (Platform.isWindows) {
      iconPath = 'windows/runner/resources/tray_icon.ico';
    } else if (Platform.isMacOS) {
      iconPath = 'assets/images/tray_icon.png';
    } else {
      iconPath = 'assets/images/logo.png';
    }
    await trayManager.setIcon(iconPath);
    
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Rhei',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit_app',
          label: 'Quit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }

  Future<void> updateTitle(String text) async {
    await trayManager.setTitle(text);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.setSkipTaskbar(false);
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.setSkipTaskbar(false);
    } else if (menuItem.key == 'quit_app') {
      // Force exit the app
      windowManager.destroy();
      exit(0);
    }
  }
}
