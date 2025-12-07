import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/tray_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io';

enum TimerMode { focus, shortBreak, longBreak }

// Background Callback for HomeWidget
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  debugPrint("Background Callback Triggered! URI: $uri");
  if (uri?.host == 'toggle') {
    // Try to find the main isolate port
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('flow_timer_service_port');
    debugPrint("Background Callback: Port found? ${sendPort != null}");
    if (sendPort != null) {
      sendPort.send('toggle');
      debugPrint("Background Callback: Sent toggle message");
    } else {
      debugPrint("Background Callback: Port NOT found. App isolate might be dead.");
    }
  }
}

class TimerService with ChangeNotifier {
  static const platform = MethodChannel('com.example.flow/timer');

  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  TimerMode _currentMode = TimerMode.focus;
  
  // Isolate Communication
  final ReceivePort _port = ReceivePort();

  // Settings
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _cycleCount = 0;
  bool _loopMode = true;
  int _tickCount = 0; // Counter for widget update throttling
  
  String _themeMode = 'system';
  bool _tickSound = true;
  String _alarmSound = 'bell';
  String _whiteNoiseSound = 'rain';
  bool _enableNotifications = true;
  bool _alwaysOnTop = false;

  // Background Settings
  String _backgroundType = 'default';
  int _backgroundColor = 0xFF2196F3;
  String _backgroundImagePath = '';
  int _contentColor = 0xFFFFFFFF; // Default White
  String _fontFamily = 'system';
  double _uiOpacity = 1.0;
  String _layoutMode = 'default';

  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Sound Players
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _whiteNoisePlayer = AudioPlayer();

  TimerService() {
    debugPrint("TimerService: Initializing...");
    _loadSettings();
    _initNotifications();
    
    // Set up white noise loop
    _whiteNoisePlayer.setReleaseMode(ReleaseMode.loop);
    
    // Register Port for Background Communication
    IsolateNameServer.removePortNameMapping('flow_timer_service_port');
    bool registered = IsolateNameServer.registerPortWithName(_port.sendPort, 'flow_timer_service_port');
    debugPrint("TimerService: Port registered? $registered");
    
    _port.listen((message) {
      debugPrint("TimerService: Received message on port: $message");
      if (message == 'toggle') {
        toggleTimer();
      }
    });
    
    // Register Background Callback
    HomeWidget.registerInteractivityCallback(backgroundCallback);
    debugPrint("TimerService: Background callback registered");
    
    // Listen for Widget Clicks (Legacy App Launch handling)
    HomeWidget.widgetClicked.listen((Uri? uri) {
      debugPrint("TimerService: Widget Clicked (Legacy Stream): $uri");
      if (uri?.host == 'toggle') {
        toggleTimer();
      }
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Getters
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  TimerMode get currentMode => _currentMode;
  int get totalSeconds => _getTotalSecondsForMode(_currentMode);
  double get progress => _remainingSeconds / totalSeconds;
  
  int get focusMinutes => _focusMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  bool get loopMode => _loopMode;
  String get themeMode => _themeMode;
  bool get tickSound => _tickSound;
  String get alarmSound => _alarmSound;
  String get whiteNoiseSound => _whiteNoiseSound;
  bool get enableNotifications => _enableNotifications;
  bool get alwaysOnTop => _alwaysOnTop;
  String get backgroundType => _backgroundType;
  int get backgroundColor => _backgroundColor;
  String get backgroundImagePath => _backgroundImagePath;
  int get contentColor => _contentColor;
  String get fontFamily => _fontFamily;
  double get uiOpacity => _uiOpacity;
  String get layoutMode => _layoutMode;

  // ...

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _focusMinutes = prefs.getInt('focusMinutes') ?? 25;
    _shortBreakMinutes = prefs.getInt('shortBreakMinutes') ?? 5;
    _longBreakMinutes = prefs.getInt('longBreakMinutes') ?? 15;
    _loopMode = prefs.getBool('loopMode') ?? true;
    _cycleCount = prefs.getInt('cycleCount') ?? 0;
    _themeMode = prefs.getString('themeMode') ?? 'system';
    _tickSound = prefs.getBool('tickSound') ?? true;

    _alarmSound = prefs.getString('alarmSound') ?? 'bell';
    _whiteNoiseSound = prefs.getString('whiteNoiseSound') ?? 'rain';
    _enableNotifications = prefs.getBool('enableNotifications') ?? true;
    _alwaysOnTop = prefs.getBool('alwaysOnTop') ?? false;
    
    _backgroundType = prefs.getString('backgroundType') ?? 'default';
    _backgroundColor = prefs.getInt('backgroundColor') ?? 0xFF2196F3;
    _backgroundImagePath = prefs.getString('backgroundImagePath') ?? '';
    _contentColor = prefs.getInt('contentColor') ?? 0xFFFFFFFF;
    _fontFamily = prefs.getString('fontFamily') ?? 'system';
    _uiOpacity = prefs.getDouble('uiOpacity') ?? 1.0;
    _layoutMode = prefs.getString('layoutMode') ?? 'default';
    
    // Initialize timer with saved focus duration since we start in focus mode
    if (_currentMode == TimerMode.focus) {
      _remainingSeconds = _focusMinutes * 60;
    }

    // Apply window settings
    if (_alwaysOnTop) {
      _applyAlwaysOnTop(true);
    }

    _manageWhiteNoise();
    _updateWidget();
    notifyListeners();
  }

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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (focus != null) {
      _focusMinutes = focus;
      await prefs.setInt('focusMinutes', focus);
      if (_currentMode == TimerMode.focus && !_isRunning) {
        _remainingSeconds = focus * 60;
      }
    }
    if (shortBreak != null) {
      _shortBreakMinutes = shortBreak;
      await prefs.setInt('shortBreakMinutes', shortBreak);
      if (_currentMode == TimerMode.shortBreak && !_isRunning) {
        _remainingSeconds = shortBreak * 60;
      }
    }
    if (longBreak != null) {
      _longBreakMinutes = longBreak;
      await prefs.setInt('longBreakMinutes', longBreak);
      if (_currentMode == TimerMode.longBreak && !_isRunning) {
        _remainingSeconds = longBreak * 60;
      }
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
      previewSound(alarmSound);
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
    
    // Check if we need to update white noise (e.g. if we add a noise setting later)
    _manageWhiteNoise();
    
    notifyListeners();
  }

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

  int _getTotalSecondsForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return _focusMinutes * 60;
      case TimerMode.shortBreak:
        return _shortBreakMinutes * 60;
      case TimerMode.longBreak:
        return _longBreakMinutes * 60;
    }
  }

  void setMode(TimerMode mode) {
    _stopTimer(resetUI: false);
    _currentMode = mode;
    _remainingSeconds = _getTotalSecondsForMode(mode);
    _updateBadge();
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      _stopTimer(resetUI: false);
    } else {
      _startTimer();
    }
  }

  void resetTimer() {
    _stopTimer(resetUI: true);
    _remainingSeconds = _getTotalSecondsForMode(_currentMode);
    _updateBadge();
    notifyListeners();
  }

  void skip() {
    _stopTimer(resetUI: false);
    
    TimerMode nextMode;
    if (_currentMode == TimerMode.focus) {
      _cycleCount++;
      if (_cycleCount % 4 == 0) {
        nextMode = TimerMode.longBreak;
      } else {
        nextMode = TimerMode.shortBreak;
      }
    } else {
      nextMode = TimerMode.focus;
    }
    
    setMode(nextMode);
    
    // If loop mode is on, we essentially "fast forward" to the next running state
    if (_loopMode) {
      _startTimer();
    }
  }

  void _startTimer() {
    _isRunning = true;
    _tickCount = 0; // Reset tick counter
    _manageWhiteNoise(); // Start noise if needed
    _updateWidget(); // Immediate update to show "Running" state
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _tickCount++;
        _updateBadge(); // Update tray only, not widget
        
        // Update widget every second for time display
        // Android side will use state caching to avoid unnecessary redraws
        _updateWidget();
        
        // Tick sound
        if (_tickSound) {
          // Use system click sound as a simple tick
          SystemSound.play(SystemSoundType.click);
        }
        
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
    notifyListeners();
  }

  void _stopTimer({required bool resetUI}) {
    _timer?.cancel();
    _isRunning = false;
    _whiteNoisePlayer.stop(); // Stop noise
    if (resetUI) {
      _clearBadge();
    }
    _updateWidget(); // Immediate update to show "Paused" state
    notifyListeners();
  }

  Future<void> _onTimerComplete() async {
    _stopTimer(resetUI: true);
    HapticFeedback.heavyImpact();
    
    // Show Notification
    if (_enableNotifications) {
      String title = _currentMode == TimerMode.focus ? "Focus Session Complete!" : "Break Over!";
      String body = _currentMode == TimerMode.focus ? "Time to take a break." : "Ready to focus again?";
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('flow_timer_channel', 'Timer Notifications',
              channelDescription: 'Notifications for timer completion',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker');
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
          
      await _notificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
    }

    // Auto-switch logic
    // Play Completion Sound
    _playCompletionSound();

    // Loop / Cycle Logic
    if (_loopMode) {
      if (_currentMode == TimerMode.focus) {
        _cycleCount++;
        if (_cycleCount % 4 == 0) {
          // 4th Focus done -> Long Break
          setMode(TimerMode.longBreak);
        } else {
          // Standard Focus done -> Short Break
          setMode(TimerMode.shortBreak);
        }
        _startTimer();
      } else {
        // Break done -> Back to Focus
        setMode(TimerMode.focus);
        _startTimer();
      }
    } else {
      // If not looping, we might still want to advance the mode but PAUSE?
      // For now, standard behavior is just stop.
      // But maybe we reset the *next* mode ready to go?
      // Let's keep it simple: Stop.
    }
    
    notifyListeners();
  }

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> previewSound(String soundName) async {
    try {
      String fileName = 'alarms/bell.mp3';
      if (soundName == 'digital') fileName = 'alarms/digital.mp3';
      // Add more mapping or use soundName directly if it matches filename
      
      await _alarmPlayer.stop();
      await _alarmPlayer.play(AssetSource('sounds/$fileName'));
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (kDebugMode) print("Error previewing sound: $e");
    }
  }

  void _playCompletionSound() {
    previewSound(_alarmSound);
  }

  Future<void> _manageWhiteNoise() async {
    if (_isRunning && _currentMode == TimerMode.focus) {
      if (_whiteNoiseSound == 'none') {
        await _whiteNoisePlayer.stop();
        return;
      }

      try {
         // Determine file based on selection
         String fileName = 'ambient/rain.mp3';
         if (_whiteNoiseSound == 'forest') fileName = 'ambient/forest.mp3';
         
         // Only switch if different or not playing
         // Note: AudioPlayer doesn't easily expose "current source", so we might just play. 
         // But re-playing might restart loop. Ideally we check if it is already playing this source. 
         // For MPV/simple players, stopping and starting is safest to switch tracks.
         
         // If already playing, we might want to check if the source changed. 
         // For now, let's just stop and play if it's supposed to be playing.
         // A better optimization would be to track `_currentWhiteNoiseSource`.
         
         if (_whiteNoisePlayer.state == PlayerState.playing) {
             // If we just changed the sound (called from updateSettings), we want to switch.
             // But if we called this from startTimer, it might be redundant.
             // Let's rely on stop() then play() for simplicity.
             await _whiteNoisePlayer.stop();
         }
         
         await _whiteNoisePlayer.play(AssetSource('sounds/$fileName'));
      } catch (e) {
         if (kDebugMode) print("Error playing white noise: $e");
      }
    } else {
      await _whiteNoisePlayer.stop();
    }
  }

  void _updateBadge() {
    try {
      String timeText = formattedTime;
      // Update Tray Title via TrayService ONLY
      TrayService().updateTitle(timeText);
      // Widget update is now handled separately (every 5s or on state change)
    } catch (e) {
      if (kDebugMode) print("Error updating badge/tray: $e");
    }
  }

  Future<void> _updateWidget() async {
    try {
      if (Platform.isAndroid) {
        // Calculate progress (0-100)
        int progressValue = (progress * 100).toInt();
        await HomeWidget.saveWidgetData<int>('progress', progressValue);
        
        await HomeWidget.saveWidgetData<String>('time', formattedTime);
        await HomeWidget.saveWidgetData<String>('status', _currentMode == TimerMode.focus ? 'Focusing' : 'Break');
        
        // Sync State
        await HomeWidget.saveWidgetData<bool>('isRunning', _isRunning);
        
        // Sync Styles
        await HomeWidget.saveWidgetData<int>('contentColor', _contentColor);
        await HomeWidget.saveWidgetData<int>('backgroundColor', _backgroundColor);
        await HomeWidget.saveWidgetData<String>('backgroundType', _backgroundType);
        await HomeWidget.saveWidgetData<String>('backgroundPath', _backgroundImagePath);

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

  void _clearBadge() {
    try {
      // Reset tray title when cleared (stopped/reset)
      TrayService().updateTitle(formattedTime); 
    } catch (e) {
       // Ignore
    }
  }
  @override
  void dispose() {
    _timer?.cancel();
    _alarmPlayer.dispose();
    _whiteNoisePlayer.dispose();
    super.dispose();
  }
}
