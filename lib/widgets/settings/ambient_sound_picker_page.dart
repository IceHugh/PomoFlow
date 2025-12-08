import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../timer_service.dart';
import 'sound_picker_page.dart';

/// Show ambient sound picker as bottom sheet
void showAmbientSoundPicker(BuildContext context) {
  final timerService = Provider.of<TimerService>(context, listen: false);
  bool isLoading = false;

  Future<void> pickAudioFile() async {
    try {
      isLoading = true;
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'wma'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await timerService.addCustomAmbientSound(result.files.single.path!);
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to add audio file: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteSound(String id, String name) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Sound'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await timerService.deleteCustomAmbientSound(id);
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete sound: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  showSoundPicker(
    context: context,
    title: 'Focus Sounds',
    getSoundItems: () {
      final allSoundItems = [
        const SoundItem(
          id: 'none',
          name: 'None',
          icon: CupertinoIcons.speaker_slash_fill,
          type: SoundType.none,
        ),
        const SoundItem(
          id: 'brook',
          name: 'Brook',
          icon: CupertinoIcons.drop_fill,
          type: SoundType.builtin,
        ),
        const SoundItem(
          id: 'ocean',
          name: 'Ocean',
          icon: CupertinoIcons.wind,
          type: SoundType.builtin,
        ),
        const SoundItem(
          id: 'rain',
          name: 'Rain',
          icon: CupertinoIcons.cloud_rain_fill,
          type: SoundType.builtin,
        ),
        ...timerService.customAmbientSounds.map((s) => SoundItem(
          id: s.id,
          name: s.name,
          icon: CupertinoIcons.music_note,
          type: SoundType.custom,
        )),
        const SoundItem(
          id: 'add',
          name: 'Add',
          icon: CupertinoIcons.add,
          type: SoundType.add,
        ),
      ];
      return allSoundItems
          .where((item) => !timerService.hiddenSoundIds.contains(item.id))
          .toList();
    },
    getCurrentSelection: () => timerService.whiteNoiseSound,
    isLoading: isLoading,
    isAmbientSound: true, // Enable 5-second preview for ambient sounds
    onSelect: (id) {
      if (id == 'add') {
        pickAudioFile();
      } else {
        timerService.updateSettings(whiteNoiseSound: id);
      }
    },
    onDelete: (id, name) => deleteSound(id, name),
  );
}
