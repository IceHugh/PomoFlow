import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/custom_ambient_sound.dart';
import '../timer_service.dart';

class AmbientSoundManager {
  // Dual-buffer players for seamless looping
  final AudioPlayer _player1 = AudioPlayer();
  final AudioPlayer _player2 = AudioPlayer();
  
  // Track current sound and playback state
  String? _currentSoundId;
  bool _isPlaying = false;
  
  // Subscriptions for player events
  StreamSubscription? _player1Subscription;
  StreamSubscription? _player2Subscription;
  
  List<CustomAmbientSound> _customAmbientSounds = [];
  
  List<String> _hiddenSoundIds = [];
  List<String> get hiddenSoundIds => _hiddenSoundIds;

  // Load custom ambient sounds and hidden sounds
  Future<void> loadCustomSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load custom sounds
      final customSoundsJson = prefs.getString('customAmbientSounds');
      if (customSoundsJson != null) {
        final List<dynamic> soundsList = jsonDecode(customSoundsJson);
        _customAmbientSounds = soundsList
            .map((json) => CustomAmbientSound.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Load hidden sounds
      _hiddenSoundIds = prefs.getStringList('hiddenSoundIds') ?? [];
      
    } catch (e) {
      if (kDebugMode) print('Error loading data: $e');
      _customAmbientSounds = [];
      _hiddenSoundIds = [];
    }
  }

  // Save hidden sounds
  Future<void> _saveHiddenSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hiddenSoundIds', _hiddenSoundIds);
    } catch (e) {
      if (kDebugMode) print('Error saving hidden sounds: $e');
    }
  }

  Future<void> hideSound(String id) async {
    if (!_hiddenSoundIds.contains(id)) {
      _hiddenSoundIds.add(id);
      await _saveHiddenSounds();
    }
  }

  // ... existing code ...
  
  List<CustomAmbientSound> get customAmbientSounds => _customAmbientSounds;



  // Save custom ambient sounds to SharedPreferences
  Future<void> _saveCustomSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundsJson = jsonEncode(_customAmbientSounds.map((s) => s.toJson()).toList());
      await prefs.setString('customAmbientSounds', soundsJson);
    } catch (e) {
      if (kDebugMode) print('Error saving custom ambient sounds: $e');
    }
  }

  // Add custom ambient sound from local file
  Future<void> addCustomSound(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final ambientDir = Directory('${appDir.path}/ambient');
      
      // Create ambient directory if not exists
      if (!await ambientDir.exists()) {
        await ambientDir.create(recursive: true);
      }

      // Get file name and extension
      final sourceFile = File(sourcePath);
      final fileName = sourcePath.split('/').last;
      final extension = fileName.split('.').last;
      
      // Generate unique ID and file name
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newFileName = 'custom_$id.$extension';
      final newPath = '${ambientDir.path}/$newFileName';

      // Copy file to app directory
      await sourceFile.copy(newPath);

      // Create custom sound object
      final customSound = CustomAmbientSound(
        id: id,
        name: fileName,
        filePath: newPath,
      );

      // Add to list and save
      _customAmbientSounds.add(customSound);
      await _saveCustomSounds();
    } catch (e) {
      if (kDebugMode) print('Error adding custom ambient sound: $e');
      rethrow;
    }
  }

  // Delete custom ambient sound (or hide built-in)
  Future<String?> deleteCustomSound(String id) async {
    try {
      // Check if it's a built-in sound
      if (id == 'rain' || id == 'brook' || id == 'ocean') {
         await hideSound(id);
         return id;
      }

      // Find the sound
      final sound = _customAmbientSounds.firstWhere((s) => s.id == id);
      
      // Delete the file
      final file = File(sound.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from list and save
      _customAmbientSounds.removeWhere((s) => s.id == id);
      await _saveCustomSounds();
      
      // Return the ID if it was the current sound (caller should switch to 'none')
      return id;
    } catch (e) {
      if (kDebugMode) print('Error deleting custom ambient sound: $e');
      rethrow;
    }
  }

  // Play ambient sound with seamless looping
  Future<void> playSound(String soundId, bool isRunning, TimerMode mode) async {
    if (isRunning) {
      if (soundId == 'none') {
        await _stopPlayback();
        return;
      }

      // If already playing the same sound, don't restart
      if (_isPlaying && _currentSoundId == soundId) {
        return;
      }

      try {
        // Stop current playback if playing different sound
        await _stopPlayback();
        
        // Small delay to ensure stop completes
        await Future.delayed(const Duration(milliseconds: 100));

        _currentSoundId = soundId;
        _isPlaying = true;

        // Start seamless looping with dual-buffer technique
        await _startSeamlessLoop(soundId);
        
      } catch (e) {
        if (kDebugMode) print("Error playing white noise: $e");
        _isPlaying = false;
        _currentSoundId = null;
      }
    } else {
      await _stopPlayback();
    }
  }

  // Start seamless looping using dual-buffer technique
  Future<void> _startSeamlessLoop(String soundId) async {
    // Configure both players for single playback (not loop)
    await _player1.setReleaseMode(ReleaseMode.release);
    await _player2.setReleaseMode(ReleaseMode.release);
    
    // Set volume to full
    await _player1.setVolume(1.0);
    await _player2.setVolume(1.0);

    // Get the audio source
    Source audioSource = await _getAudioSource(soundId);
    
    // Start first player
    await _player1.play(audioSource);

    // Listen for completion events to trigger next playback
    _player1Subscription?.cancel();
    _player2Subscription?.cancel();
    
    _player1Subscription = _player1.onPlayerComplete.listen((_) async {
      if (!_isPlaying || _currentSoundId != soundId) return;
      
      // When player1 completes, start player2
      try {
        Source source = await _getAudioSource(soundId);
        await _player2.play(source);
      } catch (e) {
        if (kDebugMode) print("Error in player1 completion handler: $e");
      }
    });

    _player2Subscription = _player2.onPlayerComplete.listen((_) async {
      if (!_isPlaying || _currentSoundId != soundId) return;
      
      // When player2 completes, start player1
      try {
        Source source = await _getAudioSource(soundId);
        await _player1.play(source);
      } catch (e) {
        if (kDebugMode) print("Error in player2 completion handler: $e");
      }
    });
  }

  // Get audio source for a sound ID
  Future<Source> _getAudioSource(String soundId) async {
    // Check if it's a built-in sound or custom sound
    if (soundId == 'rain' || soundId == 'brook' || soundId == 'ocean') {
      // Built-in sounds
      return AssetSource('sounds/ambient/$soundId.mp3');
    } else {
      // Custom sound - find by ID
      final customSound = _customAmbientSounds.firstWhere(
        (s) => s.id == soundId,
        orElse: () => throw Exception('Custom sound not found: $soundId'),
      );
      return DeviceFileSource(customSound.filePath);
    }
  }

  // Stop playback
  Future<void> _stopPlayback() async {
    _isPlaying = false;
    _currentSoundId = null;
    
    // Cancel subscriptions
    await _player1Subscription?.cancel();
    await _player2Subscription?.cancel();
    _player1Subscription = null;
    _player2Subscription = null;
    
    // Stop both players
    await _stopPlayerSafely(_player1);
    await _stopPlayerSafely(_player2);
  }

  // Stop ambient sound
  Future<void> stopSound() async {
    await _stopPlayback();
  }
  
  // Helper method to safely stop a specific player
  Future<void> _stopPlayerSafely(AudioPlayer player) async {
    if (player.state == PlayerState.playing || 
        player.state == PlayerState.paused) {
      await player.stop();
    }
  }

  void dispose() {
    // Cancel subscriptions
    _player1Subscription?.cancel();
    _player2Subscription?.cancel();
    
    // Stop and dispose both players
    if (_player1.state == PlayerState.playing || 
        _player1.state == PlayerState.paused) {
      _player1.stop();
    }
    _player1.dispose();
    
    if (_player2.state == PlayerState.playing || 
        _player2.state == PlayerState.paused) {
      _player2.stop();
    }
    _player2.dispose();
  }
}
