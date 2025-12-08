import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../timer_service.dart';
import '../services/tray_service.dart';

class WidgetManager {
  // Update Android widget
  Future<void> updateWidget({
    required String time,
    required int progress,
    required String status,
    required bool isRunning,
    required TimerMode mode,
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int contentColor,
    required int backgroundColor,
    required String backgroundType,
    required String backgroundPath,
  }) async {
    try {
      if (Platform.isAndroid) {
        // Calculate progress (0-100)
        await HomeWidget.saveWidgetData<int>('progress', progress);
        
        await HomeWidget.saveWidgetData<String>('time', time);
        await HomeWidget.saveWidgetData<String>('status', status);
        
        // Sync State
        await HomeWidget.saveWidgetData<bool>('isRunning', isRunning);
        
        // Sync timer duration settings (for widget to show initial time when stopped)
        await HomeWidget.saveWidgetData<int>('focusMinutes', focusMinutes);
        await HomeWidget.saveWidgetData<int>('shortBreakMinutes', shortBreakMinutes);
        await HomeWidget.saveWidgetData<int>('longBreakMinutes', longBreakMinutes);
        
        // Sync Styles
        await HomeWidget.saveWidgetData<int>('contentColor', contentColor);
        await HomeWidget.saveWidgetData<int>('backgroundColor', backgroundColor);
        await HomeWidget.saveWidgetData<String>('backgroundType', backgroundType);
        await HomeWidget.saveWidgetData<String>('backgroundPath', backgroundPath);

        await HomeWidget.updateWidget(
          name: 'TimerWidgetProvider',
          androidName: 'TimerWidgetProvider',
          qualifiedAndroidName: 'com.example.flow.flow.TimerWidgetProvider',
        );
      }
    } catch (e) {
      if (kDebugMode) print("Error updating widget: $e");
    }
  }

  // Update badge/tray
  void updateBadge(String time) {
    try {
      // Update Tray Title via TrayService ONLY
      TrayService().updateTitle(time);
    } catch (e) {
      if (kDebugMode) print("Error updating badge/tray: $e");
    }
  }

  // Clear badge
  void clearBadge(String time) {
    try {
      // Reset tray title when cleared (stopped/reset)
      TrayService().updateTitle(time);
    } catch (e) {
       // Ignore
    }
  }
}
