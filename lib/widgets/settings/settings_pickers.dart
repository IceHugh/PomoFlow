

import 'package:flutter/cupertino.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import '../../timer_service.dart';

class SettingsPickers {
  static void showPicker(BuildContext context, String title, int initialValue, Function(int) onChanged) {
    int selectedValue = initialValue;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 250,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        onChanged(selectedValue);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialValue - 1,
                    ),
                    onSelectedItemChanged: (int index) {
                      setState(() {
                         selectedValue = index + 1;
                      });
                    },
                    children: List<Widget>.generate(60, (int index) {
                      return Center(
                        child: Text(
                          '${index + 1} min',
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showSoundPicker(BuildContext context, TimerService timerService, Function(String) onChanged) {
    final sounds = ['bell', 'digital', 'none'];
    final soundNames = {'bell': 'Bell', 'digital': 'Digital', 'none': 'None'};
    String selectedSound = timerService.alarmSound;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 250,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Alarm Sound', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        onChanged(selectedSound);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: sounds.indexOf(timerService.alarmSound),
                    ),
                    onSelectedItemChanged: (int index) {
                      setState(() {
                         selectedSound = sounds[index];
                      });
                      timerService.previewSound(selectedSound);
                    },
                    children: sounds.map((s) => Center(child: Text(soundNames[s]!))).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showColorPicker(BuildContext context, TimerService timerService) {
    Color selectedColor = Color(timerService.backgroundColor);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 500,
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                         timerService.updateSettings(backgroundColor: selectedColor.toARGB32());
                         Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: ColorPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      setState(() => selectedColor = color);
                    },
                    labelTypes: const [],
                    pickerAreaHeightPercent: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showContentColorPicker(BuildContext context, TimerService timerService) {
    Color selectedColor = Color(timerService.contentColor);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 500,
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                         timerService.updateSettings(contentColor: selectedColor.toARGB32());
                         Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: ColorPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      setState(() => selectedColor = color);
                    },
                    labelTypes: const [],
                    pickerAreaHeightPercent: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> pickImage(TimerService timerService) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      String? path = result.files.single.path;
      if (path != null) {
        await timerService.saveBackgroundImage(path);
      }
    }
  }

  static void showFontPicker(BuildContext context, TimerService timerService) {
    // Curated list of common cross-platform fonts
    final fonts = [
      'system',
      'Arial',
      'Verdana',
      'Tahoma',
      'Trebuchet MS',
      'Times New Roman',
      'Georgia',
      'Garamond',
      'Courier New',
      'Brush Script MT',
      'Comic Sans MS',
      'Impact',
    ];
    


    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Font', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: fonts.contains(timerService.fontFamily) 
                        ? fonts.indexOf(timerService.fontFamily) 
                        : 0,
                  ),
                  onSelectedItemChanged: (int index) {
                    timerService.updateSettings(fontFamily: fonts[index]);
                  },
                  children: fonts.map((font) => Center(
                    child: Text(
                      font == 'system' ? 'System Default' : '25:00',
                      style: TextStyle(
                        fontFamily: font == 'system' ? null : font,
                        fontSize: 24, 
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showWhiteNoisePicker(BuildContext context, TimerService timerService, Function(String) onChanged) {
    final sounds = ['rain', 'forest', 'none'];
    final soundNames = {'rain': 'Rain', 'forest': 'Forest', 'none': 'None'};
    String selectedSound = timerService.whiteNoiseSound;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 250,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Focus Sound', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                         onChanged(selectedSound);
                         Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: sounds.contains(timerService.whiteNoiseSound) ? sounds.indexOf(timerService.whiteNoiseSound) : 0,
                    ),
                    onSelectedItemChanged: (int index) {
                      setState(() {
                         selectedSound = sounds[index];
                      });
                      // No preview for white noise loop
                    },
                    children: sounds.map((s) => Center(child: Text(soundNames[s]!))).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  static void showCarouselIntervalPicker(BuildContext context, TimerService timerService) {
    // Generate valid intervals
    final List<int> intervals = [5, 6, 10, 15, 20, 25, 30, 45, 60];
    
    // Ensure current value is handled
    int initialIndex = intervals.indexOf(timerService.backgroundCarouselInterval);
    if (initialIndex == -1) initialIndex = 1; // Default to 6s (index 1)

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Interval', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (int index) {
                    timerService.updateSettings(backgroundCarouselInterval: intervals[index]);
                  },
                  children: intervals.map((interval) => Center(
                    child: Text('$interval sec'),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
