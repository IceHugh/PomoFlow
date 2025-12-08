import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/custom_ambient_sound.dart';
import '../timer_service.dart';

class AmbientSoundManager {
  final AudioPlayer _whiteNoisePlayer = AudioPlayer();
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
      if (id == 'rain' || id == 'forest') {
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

  // Play ambient sound
  Future<void> playSound(String soundId, bool isRunning, TimerMode mode) async {
    if (isRunning && mode == TimerMode.focus) {
      if (soundId == 'none') {
        await _whiteNoisePlayer.stop();
        return;
      }

      try {
        // Stop current playback if playing
        if (_whiteNoisePlayer.state == PlayerState.playing) {
          await _whiteNoisePlayer.stop();
        }

        // Check if it's a built-in sound or custom sound
        if (soundId == 'rain' || soundId == 'forest') {
          // Built-in sounds
          String fileName = soundId == 'rain' ? 'ambient/rain.mp3' : 'ambient/forest.mp3';
          await _whiteNoisePlayer.play(AssetSource('sounds/$fileName'));
        } else {
          // Custom sound - find by ID
          try {
            final customSound = _customAmbientSounds.firstWhere(
              (s) => s.id == soundId,
            );
            await _whiteNoisePlayer.play(DeviceFileSource(customSound.filePath));
          } catch (e) {
            if (kDebugMode) print('Custom sound not found, ID: $soundId');
            // If custom sound not found, stop playback
            await _whiteNoisePlayer.stop();
          }
        }
      } catch (e) {
        if (kDebugMode) print("Error playing white noise: $e");
      }
    } else {
      await _whiteNoisePlayer.stop();
    }
  }

  // Stop ambient sound
  Future<void> stopSound() async {
    await _whiteNoisePlayer.stop();
  }

  void dispose() {
    _whiteNoisePlayer.dispose();
  }
}
