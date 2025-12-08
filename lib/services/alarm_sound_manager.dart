import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/custom_ambient_sound.dart';

/// Manager for alarm sounds (both built-in and custom)
class AlarmSoundManager {
  List<CustomAmbientSound> _customAlarmSounds = [];
  List<String> _hiddenSoundIds = [];
  
  List<CustomAmbientSound> get customAlarmSounds => _customAlarmSounds;
  List<String> get hiddenSoundIds => _hiddenSoundIds;

  // Load custom alarm sounds and hidden sounds
  Future<void> loadCustomSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load custom sounds
      final customSoundsJson = prefs.getString('customAlarmSounds');
      if (customSoundsJson != null) {
        final List<dynamic> soundsList = jsonDecode(customSoundsJson);
        _customAlarmSounds = soundsList
            .map((json) => CustomAmbientSound.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Load hidden sounds
      _hiddenSoundIds = prefs.getStringList('hiddenAlarmSoundIds') ?? [];
      
    } catch (e) {
      if (kDebugMode) print('Error loading alarm sound data: $e');
      _customAlarmSounds = [];
      _hiddenSoundIds = [];
    }
  }

  // Save custom alarm sounds to SharedPreferences
  Future<void> _saveCustomSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundsJson = jsonEncode(_customAlarmSounds.map((s) => s.toJson()).toList());
      await prefs.setString('customAlarmSounds', soundsJson);
    } catch (e) {
      if (kDebugMode) print('Error saving custom alarm sounds: $e');
    }
  }

  // Save hidden sounds
  Future<void> _saveHiddenSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hiddenAlarmSoundIds', _hiddenSoundIds);
    } catch (e) {
      if (kDebugMode) print('Error saving hidden alarm sounds: $e');
    }
  }

  Future<void> hideSound(String id) async {
    if (!_hiddenSoundIds.contains(id)) {
      _hiddenSoundIds.add(id);
      await _saveHiddenSounds();
    }
  }

  // Add custom alarm sound from local file
  Future<void> addCustomSound(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final alarmDir = Directory('${appDir.path}/alarms');
      
      // Create alarms directory if not exists
      if (!await alarmDir.exists()) {
        await alarmDir.create(recursive: true);
      }

      // Get file name and extension
      final sourceFile = File(sourcePath);
      final fileName = sourcePath.split('/').last;
      final extension = fileName.split('.').last;
      
      // Generate unique ID and file name
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newFileName = 'custom_$id.$extension';
      final newPath = '${alarmDir.path}/$newFileName';

      // Copy file to app directory
      await sourceFile.copy(newPath);

      // Create custom sound object
      final customSound = CustomAmbientSound(
        id: id,
        name: fileName,
        filePath: newPath,
      );

      // Add to list and save
      _customAlarmSounds.add(customSound);
      await _saveCustomSounds();
    } catch (e) {
      if (kDebugMode) print('Error adding custom alarm sound: $e');
      rethrow;
    }
  }

  // Delete custom alarm sound (or hide built-in)
  Future<String?> deleteCustomSound(String id) async {
    try {
      // Check if it's a built-in sound
      if (id == 'bell' || id == 'digital') {
         await hideSound(id);
         return id;
      }

      // Find the sound
      final sound = _customAlarmSounds.firstWhere((s) => s.id == id);
      
      // Delete the file
      final file = File(sound.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from list and save
      _customAlarmSounds.removeWhere((s) => s.id == id);
      await _saveCustomSounds();
      
      // Return the ID if it was the current sound (caller should switch to 'none')
      return id;
    } catch (e) {
      if (kDebugMode) print('Error deleting custom alarm sound: $e');
      rethrow;
    }
  }
}
