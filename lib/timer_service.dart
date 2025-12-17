import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io';
import 'models/custom_ambient_sound.dart';
import 'models/background_image.dart';
import 'services/ambient_sound_manager.dart';
import 'services/alarm_sound_manager.dart';
import 'services/background_manager.dart';
import 'services/settings_manager.dart';
import 'services/widget_manager.dart';
import 'services/stats_service.dart';
import 'models/focus_session.dart';

enum TimerMode { focus, shortBreak, longBreak }

// Background Callback for HomeWidget
@pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'toggle') {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('flow_timer_service_port');
    if (sendPort != null) {
      sendPort.send('toggle');
    }
  }
}

class TimerService with ChangeNotifier, WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.flow/timer');

  // Services
  final AmbientSoundManager _ambientSoundManager = AmbientSoundManager();
  final AlarmSoundManager _alarmSoundManager = AlarmSoundManager();
  final BackgroundManager _backgroundManager = BackgroundManager();
  final SettingsManager _settingsManager = SettingsManager();
  final WidgetManager _widgetManager = WidgetManager();

  // Timer state
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  TimerMode _currentMode = TimerMode.focus;
  int _cycleCount = 0;
  
  // Isolate Communication
  final ReceivePort _port = ReceivePort();

  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Sound Players
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer(); // Separate player for previews

  TimerService() {
    _loadSettings();
    _initNotifications();
    
    // Register lifecycle observer for desktop platforms to handle system sleep
    if (Platform.isMacOS || Platform.isWindows) {
      WidgetsBinding.instance.addObserver(this);
    }
    
    // Register Port for Background Communication (Android only)
    if (Platform.isAndroid) {
      IsolateNameServer.removePortNameMapping('flow_timer_service_port');
      IsolateNameServer.registerPortWithName(_port.sendPort, 'flow_timer_service_port');
      
      _port.listen((message) {
        if (message == 'toggle') {
          toggleTimer();
        }
      });
      
      HomeWidget.registerInteractivityCallback(backgroundCallback);
      HomeWidget.saveWidgetData<String>('time', '');
      
      HomeWidget.widgetClicked.listen((Uri? uri) {
        if (uri?.host == 'toggle') {
          toggleTimer();
        }
      });
    }
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
  
  // Settings getters (delegate to SettingsManager)
  int get focusMinutes => _settingsManager.focusMinutes;
  int get shortBreakMinutes => _settingsManager.shortBreakMinutes;
  int get longBreakMinutes => _settingsManager.longBreakMinutes;
  bool get loopMode => _settingsManager.loopMode;
  String get themeMode => _settingsManager.themeMode;
  bool get tickSound => _settingsManager.tickSound;
  String get alarmSound => _settingsManager.alarmSound;
  String get whiteNoiseSound => _settingsManager.whiteNoiseSound;
  bool get enableNotifications => _settingsManager.enableNotifications;
  bool get alwaysOnTop => _settingsManager.alwaysOnTop;
  String get backgroundType => _settingsManager.backgroundType;
  int get backgroundColor => _settingsManager.backgroundColor;
  String get backgroundImagePath => _settingsManager.backgroundImagePath;
  int get contentColor => _settingsManager.contentColor;
  String get fontFamily => _settingsManager.fontFamily;
  double get uiOpacity => _settingsManager.uiOpacity;
  String get layoutMode => _settingsManager.layoutMode;
  int get backgroundCarouselInterval => _settingsManager.backgroundCarouselInterval;
  
  // Ambient sound getters (delegate to AmbientSoundManager)
  List<CustomAmbientSound> get customAmbientSounds => _ambientSoundManager.customAmbientSounds;
  List<String> get hiddenSoundIds => _ambientSoundManager.hiddenSoundIds;
  
  // Alarm sound getters (delegate to AlarmSoundManager)
  List<CustomAmbientSound> get customAlarmSounds => _alarmSoundManager.customAlarmSounds;
  List<String> get hiddenAlarmSoundIds => _alarmSoundManager.hiddenSoundIds;
  int get cycleCount => _cycleCount;
  
  // Background image getters (delegate to BackgroundManager)
  List<BackgroundImage> get backgroundImages => _backgroundManager.backgroundImages;
  List<BackgroundImage> get selectedBackgroundImages => _backgroundManager.selectedImages;

  Future<void> _loadSettings() async {
    await _settingsManager.loadSettings();
    await _ambientSoundManager.loadCustomSounds();
    await _alarmSoundManager.loadCustomSounds();
    await _backgroundManager.loadBackgroundImages();
    
    // Initialize timer with saved focus duration since we start in focus mode
    if (_currentMode == TimerMode.focus) {
      _remainingSeconds = _settingsManager.focusMinutes * 60;
    }

    _manageWhiteNoise();
    _updateWidget();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only handle on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows) return;
    
    if (state == AppLifecycleState.paused) {
      // System is going to sleep, pause timer if running
      if (_isRunning) {
        _stopTimer(resetUI: false);
      }
    }
    // Note: We don't auto-resume on AppLifecycleState.resumed
    // User needs to manually start the timer again
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
    int? backgroundCarouselInterval,
  }) async {
    await _settingsManager.updateSettings(
      focus: focus,
      shortBreak: shortBreak,
      longBreak: longBreak,
      loopMode: loopMode,
      themeMode: themeMode,
      tickSound: tickSound,
      alarmSound: alarmSound,
      whiteNoiseSound: whiteNoiseSound,
      enableNotifications: enableNotifications,
      alwaysOnTop: alwaysOnTop,
      backgroundType: backgroundType,
      backgroundColor: backgroundColor,
      backgroundImagePath: backgroundImagePath,
      contentColor: contentColor,
      fontFamily: fontFamily,
      uiOpacity: uiOpacity,
      layoutMode: layoutMode,
      backgroundCarouselInterval: backgroundCarouselInterval,
    );
    
    // Update timer if duration changed
    if (focus != null && _currentMode == TimerMode.focus && !_isRunning) {
      _remainingSeconds = focus * 60;
    }
    if (shortBreak != null && _currentMode == TimerMode.shortBreak && !_isRunning) {
      _remainingSeconds = shortBreak * 60;
    }
    if (longBreak != null && _currentMode == TimerMode.longBreak && !_isRunning) {
      _remainingSeconds = longBreak * 60;
    }
    
    // Preview alarm sound if changed
    if (alarmSound != null) {
      previewSound(alarmSound);
    }
    
    // Update white noise if changed
    _manageWhiteNoise();
    
    notifyListeners();
  }

  Future<void> saveBackgroundImage(String sourcePath) async {
    await _settingsManager.saveBackgroundImage(sourcePath);
    notifyListeners();
  }

  Future<void> addCustomAmbientSound(String sourcePath) async {
    await _ambientSoundManager.addCustomSound(sourcePath);
    notifyListeners();
  }

  Future<void> deleteCustomAmbientSound(String id) async {
    final deletedId = await _ambientSoundManager.deleteCustomSound(id);
    
    // If deleted sound was selected, switch to 'none'
    if (deletedId == _settingsManager.whiteNoiseSound) {
      await updateSettings(whiteNoiseSound: 'none');
    }
    
    notifyListeners();
  }

  Future<void> addCustomAlarmSound(String sourcePath) async {
    await _alarmSoundManager.addCustomSound(sourcePath);
    notifyListeners();
  }

  Future<void> deleteCustomAlarmSound(String id) async {
    final deletedId = await _alarmSoundManager.deleteCustomSound(id);
    
    // If deleted sound was selected, switch to 'none'
    if (deletedId == _settingsManager.alarmSound) {
      await updateSettings(alarmSound: 'none');
    }
    
    notifyListeners();
  }

  // Background image management methods
  Future<void> addBackgroundImage(String sourcePath) async {
    await _backgroundManager.addBackgroundImage(sourcePath);
    notifyListeners();
  }

  Future<void> deleteBackgroundImage(String id) async {
    await _backgroundManager.deleteBackgroundImage(id);
    notifyListeners();
  }

  Future<void> toggleBackgroundImageSelection(String id) async {
    await _backgroundManager.toggleImageSelection(id);
    notifyListeners();
  }


  int _getTotalSecondsForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return _settingsManager.focusMinutes * 60;
      case TimerMode.shortBreak:
        return _settingsManager.shortBreakMinutes * 60;
      case TimerMode.longBreak:
        return _settingsManager.longBreakMinutes * 60;
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
    if (_settingsManager.loopMode) {
      _startTimer();
    }
  }

  void _startTimer() {
    _isRunning = true;
    _manageWhiteNoise(); // Start noise if needed
    _updateWidget(); // Immediate update to show "Running" state
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        
        // Update both tray and widget every second for time sync
        _updateBadge();
        _updateWidget();
        
        // Tick sound
        if (_settingsManager.tickSound) {
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
    _ambientSoundManager.stopSound(); // Stop noise
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
    if (_settingsManager.enableNotifications) {
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

    // Play Completion Sound
    _playCompletionSound();

    // Loop / Cycle Logic
    if (_settingsManager.loopMode) {
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
        // Don't use setMode() here as it calls _stopTimer internally
        // Instead, directly update the mode and remaining time
        _currentMode = TimerMode.focus;
        _remainingSeconds = _getTotalSecondsForMode(TimerMode.focus);
        _updateBadge();
        _startTimer();
      }
    }
    
    // Save Statistics if Focus Mode completed
    if (_currentMode == TimerMode.focus) {
      try {
        await StatsService().saveSession(FocusSession(
          startTime: DateTime.now().subtract(Duration(minutes: _settingsManager.focusMinutes)),
          durationMinutes: _settingsManager.focusMinutes,
        ));
      } catch (e) {
        if (kDebugMode) print("Error saving stats: $e");
      }
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
      if (soundName == 'none') {
        return;
      }
      
      // Stop preview player only if it's currently playing or paused
      if (_previewPlayer.state == PlayerState.playing || 
          _previewPlayer.state == PlayerState.paused) {
        await _previewPlayer.stop();
      }
      
      // Small delay to ensure previous operation completes
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Check if it's a built-in sound or custom sound
      if (soundName == 'bell' || soundName == 'beep1' || soundName == 'beep2' || 
          soundName == 'chirps' || soundName == 'digital' || soundName == 'retro') {
        // Built-in alarm sounds
        await _previewPlayer.play(AssetSource('sounds/alarms/$soundName.mp3'));
      } else {
        // Custom sound - find by ID
        try {
          final customSound = _alarmSoundManager.customAlarmSounds.firstWhere(
            (s) => s.id == soundName,
          );
          await _previewPlayer.play(DeviceFileSource(customSound.filePath));
        } catch (e) {
          if (kDebugMode) print('Custom alarm sound not found, ID: $soundName');
          return;
        }
      }
      
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (kDebugMode) print("Error previewing sound: $e");
    }
  }

  Future<void> _playCompletionSound() async {
    try {
      if (_settingsManager.alarmSound == 'none') {
        return;
      }
      
      // Pause ambient sound before playing alarm
      await _ambientSoundManager.stopSound();
      
      // Stop alarm player if playing
      if (_alarmPlayer.state == PlayerState.playing || 
          _alarmPlayer.state == PlayerState.paused) {
        await _alarmPlayer.stop();
      }
      
      // Small delay to ensure previous operation completes
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Set to play once (not loop)
      await _alarmPlayer.setReleaseMode(ReleaseMode.release);
      
      // Play alarm sound
      if (_settingsManager.alarmSound == 'bell' || 
          _settingsManager.alarmSound == 'beep1' || 
          _settingsManager.alarmSound == 'beep2' ||
          _settingsManager.alarmSound == 'chirps' || 
          _settingsManager.alarmSound == 'digital' || 
          _settingsManager.alarmSound == 'retro') {
        // Built-in alarm sounds
        await _alarmPlayer.play(AssetSource('sounds/alarms/${_settingsManager.alarmSound}.mp3'));
      } else {
        // Custom sound - find by ID
        try {
          final customSound = _alarmSoundManager.customAlarmSounds.firstWhere(
            (s) => s.id == _settingsManager.alarmSound,
          );
          await _alarmPlayer.play(DeviceFileSource(customSound.filePath));
        } catch (e) {
          if (kDebugMode) print('Custom alarm sound not found, ID: ${_settingsManager.alarmSound}');
          // Resume ambient sound even if alarm failed
          _manageWhiteNoise();
          return;
        }
      }
      
      // Listen for completion and resume ambient sound
      _alarmPlayer.onPlayerComplete.listen((_) {
        _manageWhiteNoise();
      });
      
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (kDebugMode) print("Error playing completion sound: $e");
      // Resume ambient sound if error occurred
      _manageWhiteNoise();
    }
  }

  Future<void> _manageWhiteNoise() async {
    await _ambientSoundManager.playSound(
      _settingsManager.whiteNoiseSound,
      _isRunning,
      _currentMode,
    );
  }

  void _updateBadge() {
    _widgetManager.updateBadge(formattedTime);
  }

  Future<void> _updateWidget() async {
    int progressValue = (progress * 100).toInt();
    await _widgetManager.updateWidget(
      time: formattedTime,
      progress: progressValue,
      status: _currentMode == TimerMode.focus ? 'Focusing' : 'Break',
      isRunning: _isRunning,
      mode: _currentMode,
      focusMinutes: _settingsManager.focusMinutes,
      shortBreakMinutes: _settingsManager.shortBreakMinutes,
      longBreakMinutes: _settingsManager.longBreakMinutes,
      contentColor: _settingsManager.contentColor,
      backgroundColor: _settingsManager.backgroundColor,
      backgroundType: _settingsManager.backgroundType,
      backgroundPath: _settingsManager.backgroundImagePath,
    );
  }

  void _clearBadge() {
    _widgetManager.clearBadge(formattedTime);
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    if (Platform.isMacOS || Platform.isWindows) {
      WidgetsBinding.instance.removeObserver(this);
    }
    
    _timer?.cancel();
    
    // Stop and dispose audio players safely
    _stopAndDisposePlayer(_alarmPlayer);
    _stopAndDisposePlayer(_previewPlayer);
    
    _ambientSoundManager.dispose();
    super.dispose();
  }
  
  // Helper method to safely stop and dispose audio player
  void _stopAndDisposePlayer(AudioPlayer player) {
    try {
      if (player.state == PlayerState.playing || 
          player.state == PlayerState.paused) {
        player.stop();
      }
      player.dispose();
    } catch (e) {
      if (kDebugMode) print('Error disposing player: $e');
    }
  }
}
