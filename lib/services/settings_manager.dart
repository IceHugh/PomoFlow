import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';

class SettingsManager {
  // Timer settings
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  bool _loopMode = true;
  
  // Appearance settings
  String _themeMode = 'system';
  String _backgroundType = 'default';
  int _backgroundColor = 0xFF2196F3;
  String _backgroundImagePath = '';
  int _contentColor = 0xFFFFFFFF;
  String _fontFamily = 'system';
  double _uiOpacity = 1.0;
  String _layoutMode = 'default';
  int _backgroundCarouselInterval = 6; // in seconds
  
  // Sound settings
  bool _tickSound = true;
  String _alarmSound = 'bell';
  String _whiteNoiseSound = 'brook';
  
  // System settings
  bool _enableNotifications = true;
  bool _alwaysOnTop = false;
  
  // Getters
  int get focusMinutes => _focusMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  bool get loopMode => _loopMode;
  
  String get themeMode => _themeMode;
  String get backgroundType => _backgroundType;
  int get backgroundColor => _backgroundColor;
  String get backgroundImagePath => _backgroundImagePath;
  int get contentColor => _contentColor;
  String get fontFamily => _fontFamily;
  double get uiOpacity => _uiOpacity;
  String get layoutMode => _layoutMode;
  int get backgroundCarouselInterval => _backgroundCarouselInterval;
  
  bool get tickSound => _tickSound;
  String get alarmSound => _alarmSound;
  String get whiteNoiseSound => _whiteNoiseSound;
  
  bool get enableNotifications => _enableNotifications;
  bool get alwaysOnTop => _alwaysOnTop;

  // Load all settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _focusMinutes = prefs.getInt('focusMinutes') ?? 25;
    _shortBreakMinutes = prefs.getInt('shortBreakMinutes') ?? 5;
    _longBreakMinutes = prefs.getInt('longBreakMinutes') ?? 15;
    _loopMode = prefs.getBool('loopMode') ?? true;
    _themeMode = prefs.getString('themeMode') ?? 'system';
    _tickSound = prefs.getBool('tickSound') ?? true;

    _alarmSound = prefs.getString('alarmSound') ?? 'bell';
    _whiteNoiseSound = prefs.getString('whiteNoiseSound') ?? 'brook';
    _enableNotifications = prefs.getBool('enableNotifications') ?? true;
    _alwaysOnTop = prefs.getBool('alwaysOnTop') ?? false;
    
    _backgroundType = prefs.getString('backgroundType') ?? 'default';
    _backgroundColor = prefs.getInt('backgroundColor') ?? 0xFF2196F3;
    _backgroundImagePath = prefs.getString('backgroundImagePath') ?? '';
    _contentColor = prefs.getInt('contentColor') ?? 0xFFFFFFFF;
    _fontFamily = prefs.getString('fontFamily') ?? 'system';
    _uiOpacity = prefs.getDouble('uiOpacity') ?? 1.0;
    _layoutMode = prefs.getString('layoutMode') ?? 'default';
    _backgroundCarouselInterval = prefs.getInt('backgroundCarouselInterval') ?? 6;

    // Apply window settings
    if (_alwaysOnTop) {
      _applyAlwaysOnTop(true);
    }
  }

  // Update settings
  Future<void> updateSettings({
    int? focus,
    int? shortBreak,
    int? longBreak,
    bool? loopMode,
    String? themeMode,
    bool? tickSound,
    String? alarmSound,
    String? whiteNoiseSound,
    bool? enableNotifications,
    bool? alwaysOnTop,
    String? backgroundType,
    int? backgroundColor,
    String? backgroundImagePath,
    int? contentColor,
    String? fontFamily,
    double? uiOpacity,
    String? layoutMode,
    int? backgroundCarouselInterval,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (focus != null) {
      _focusMinutes = focus;
      await prefs.setInt('focusMinutes', focus);
    }
    if (shortBreak != null) {
      _shortBreakMinutes = shortBreak;
      await prefs.setInt('shortBreakMinutes', shortBreak);
    }
    if (longBreak != null) {
      _longBreakMinutes = longBreak;
      await prefs.setInt('longBreakMinutes', longBreak);
    }
    if (loopMode != null) {
      _loopMode = loopMode;
      await prefs.setBool('loopMode', loopMode);
    }
    if (themeMode != null) {
      _themeMode = themeMode;
      await prefs.setString('themeMode', themeMode);
    }
    if (tickSound != null) {
      _tickSound = tickSound;
      await prefs.setBool('tickSound', tickSound);
    }
    if (alarmSound != null) {
      _alarmSound = alarmSound;
      await prefs.setString('alarmSound', alarmSound);
    }
    if (whiteNoiseSound != null) {
      _whiteNoiseSound = whiteNoiseSound;
      await prefs.setString('whiteNoiseSound', whiteNoiseSound);
    }
    if (enableNotifications != null) {
      _enableNotifications = enableNotifications;
      await prefs.setBool('enableNotifications', enableNotifications);
    }
    if (alwaysOnTop != null) {
      _alwaysOnTop = alwaysOnTop;
      await prefs.setBool('alwaysOnTop', alwaysOnTop);
      _applyAlwaysOnTop(alwaysOnTop);
    }
    if (backgroundType != null) {
      _backgroundType = backgroundType;
      await prefs.setString('backgroundType', backgroundType);
    }
    if (backgroundColor != null) {
      _backgroundColor = backgroundColor;
      await prefs.setInt('backgroundColor', backgroundColor);
    }
    if (backgroundImagePath != null) {
      _backgroundImagePath = backgroundImagePath;
      await prefs.setString('backgroundImagePath', backgroundImagePath);
    }
    if (contentColor != null) {
      _contentColor = contentColor;
      await prefs.setInt('contentColor', contentColor);
    }
    if (fontFamily != null) {
      _fontFamily = fontFamily;
      await prefs.setString('fontFamily', fontFamily);
    }
    if (uiOpacity != null) {
      _uiOpacity = uiOpacity;
      await prefs.setDouble('uiOpacity', uiOpacity);
    }
    if (layoutMode != null) {
      _layoutMode = layoutMode;
      await prefs.setString('layoutMode', layoutMode);
    }
    if (backgroundCarouselInterval != null) {
      _backgroundCarouselInterval = backgroundCarouselInterval;
      await prefs.setInt('backgroundCarouselInterval', backgroundCarouselInterval);
    }
  }

  // Save background image
  Future<void> saveBackgroundImage(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${appDir.path}/$fileName';
      
      if (_backgroundImagePath.isNotEmpty) {
        final oldFile = File(_backgroundImagePath);
        if (await oldFile.exists() && _backgroundImagePath.startsWith(appDir.path)) {
           try {
             await oldFile.delete();
           } catch (e) {
             if (kDebugMode) print('Error deleting old background: $e');
           }
        }
      }

      // Copy new file
      final sourceFile = File(sourcePath);
      await sourceFile.copy(newPath);

      // Update settings
      await updateSettings(backgroundType: 'image', backgroundImagePath: newPath);
    } catch (e) {
      if (kDebugMode) print('Error saving background image: $e');
      await updateSettings(backgroundType: 'image', backgroundImagePath: sourcePath);
    }
  }

  void _applyAlwaysOnTop(bool alwaysOnTop) async {
    try {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting always on top: $e');
      }
    }
  }
}
