import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../timer_service.dart';
import 'sound_picker_page.dart';

/// Show alarm sound picker as bottom sheet
void showAlarmSoundPicker(BuildContext context) {
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
        await timerService.addCustomAlarmSound(result.files.single.path!);
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
        await timerService.deleteCustomAlarmSound(id);
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
    title: 'Alarm Sound',
    getSoundItems: () {
      final allSoundItems = [
        const SoundItem(
          id: 'none',
          name: 'None',
          icon: CupertinoIcons.speaker_slash_fill,
          type: SoundType.none,
        ),
        const SoundItem(
          id: 'bell',
          name: 'Bell',
          icon: CupertinoIcons.bell_fill,
          type: SoundType.builtin,
        ),
        const SoundItem(
          id: 'digital',
          name: 'Digital',
          icon: CupertinoIcons.waveform,
          type: SoundType.builtin,
        ),
        ...timerService.customAlarmSounds.map((s) => SoundItem(
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
          .where((item) => !timerService.hiddenAlarmSoundIds.contains(item.id))
          .toList();
    },
    getCurrentSelection: () => timerService.alarmSound,
    isLoading: isLoading,
    onSelect: (id) {
      if (id == 'add') {
        pickAudioFile();
      } else {
        timerService.updateSettings(alarmSound: id);
        if (id != 'none') {
          timerService.previewSound(id);
        }
      }
    },
    onDelete: (id, name) => deleteSound(id, name),
  );
}
