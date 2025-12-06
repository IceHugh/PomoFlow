import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart'; // Keep commented until assets are real, or use if we find a URL mechanism.

enum TimerMode { focus, shortBreak, longBreak }

class TimerService with ChangeNotifier {
  static const platform = MethodChannel('com.example.flow/timer');

  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  TimerMode _currentMode = TimerMode.focus;

  // Settings
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  bool _loopMode = false; // "Auto-run" / "Loop"
  int _cycleCount = 0; // Tracks consecutive focus sessions
  
  // bool _autoStartBreaks = false; // Deprecated by Loop Mode
  // bool _autoStartPomodoros = false; // Deprecated by Loop Mode
  String _themeMode = 'system'; // 'system', 'light', 'dark'
  bool _tickSound = false;
  String _alarmSound = 'bell';
  String _whiteNoiseSound = 'rain'; // Default
  bool _enableNotifications = true;
  bool _alwaysOnTop = false;

  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Sound Players
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _whiteNoisePlayer = AudioPlayer();

  TimerService() {
    _loadSettings();
    _initNotifications();
    
    // Set up white noise loop
    _whiteNoisePlayer.setReleaseMode(ReleaseMode.loop);
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

  // ...

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // ...
    _alarmSound = prefs.getString('alarmSound') ?? 'bell';
    _whiteNoiseSound = prefs.getString('whiteNoiseSound') ?? 'rain';
    _enableNotifications = prefs.getBool('enableNotifications') ?? true;
    _alwaysOnTop = prefs.getBool('alwaysOnTop') ?? false;
    
    // ...
    
    // Check white noise on load
    _manageWhiteNoise();
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (focus != null) {
      _focusMinutes = focus;
      prefs.setInt('focusMinutes', focus);
      if (_currentMode == TimerMode.focus && !_isRunning) {
        _remainingSeconds = focus * 60;
      }
    }
    if (shortBreak != null) {
      _shortBreakMinutes = shortBreak;
      prefs.setInt('shortBreakMinutes', shortBreak);
      if (_currentMode == TimerMode.shortBreak && !_isRunning) {
        _remainingSeconds = shortBreak * 60;
      }
    }
    if (longBreak != null) {
      _longBreakMinutes = longBreak;
      prefs.setInt('longBreakMinutes', longBreak);
      if (_currentMode == TimerMode.longBreak && !_isRunning) {
        _remainingSeconds = longBreak * 60;
      }
    }
    if (loopMode != null) {
      _loopMode = loopMode;
      prefs.setBool('loopMode', loopMode);
    }
    if (themeMode != null) {
      _themeMode = themeMode;
      prefs.setString('themeMode', themeMode);
    }
    if (tickSound != null) {
      _tickSound = tickSound;
      prefs.setBool('tickSound', tickSound);
    }

    if (alarmSound != null) {
      _alarmSound = alarmSound;
      prefs.setString('alarmSound', alarmSound);
      // Preview on change
      previewSound(alarmSound);
    }
    if (whiteNoiseSound != null) {
      _whiteNoiseSound = whiteNoiseSound;
      prefs.setString('whiteNoiseSound', whiteNoiseSound);
      // We don't preview loop sounds, but we update the background noise immediately
    }
    if (enableNotifications != null) {
      _enableNotifications = enableNotifications;
      prefs.setBool('enableNotifications', enableNotifications);
    }
    if (alwaysOnTop != null) {
      _alwaysOnTop = alwaysOnTop;
      prefs.setBool('alwaysOnTop', alwaysOnTop);
      _applyAlwaysOnTop(alwaysOnTop);
    }
    
    // Check if we need to update white noise (e.g. if we add a noise setting later)
    _manageWhiteNoise();
    
    notifyListeners();
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

  void _startTimer() {
    _isRunning = true;
    _manageWhiteNoise(); // Start noise if needed
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _updateBadge();
        
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
      String prefix = _currentMode == TimerMode.focus ? "🍅 " : "☕️ ";
      platform.invokeMethod('updateTimer', {'time': "$prefix$formattedTime"});
    } catch (e) {
      // Ignore
    }
  }

  void _clearBadge() {
    try {
      platform.invokeMethod('clearTimer');
    } catch (e) {
      // Ignore
    }
  }
}
