import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'timer_service.dart';
import 'widgets/glass_container.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showPicker(BuildContext context, String title, int initialValue, Function(int) onChanged) {
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    initialItem: initialValue - 1,
                  ),
                  onSelectedItemChanged: (int selectedItem) {
                    onChanged(selectedItem + 1);
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
    );
  }

  void _showSoundPicker(BuildContext context, TimerService timerService, Function(String) onChanged) {
    final sounds = ['bell', 'digital', 'none'];
    final soundNames = {'bell': 'Bell', 'digital': 'Digital', 'none': 'None'};
    
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
                  const Text('Alarm Sound', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    initialItem: sounds.indexOf(timerService.alarmSound),
                  ),
                  onSelectedItemChanged: (int index) {
                    final selectedSound = sounds[index];
                    onChanged(selectedSound);
                    timerService.previewSound(selectedSound);
                  },
                  children: sounds.map((s) => Center(child: Text(soundNames[s]!))).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showColorPicker(BuildContext context, TimerService timerService) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
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
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: ColorPicker(
                  pickerColor: Color(timerService.backgroundColor),
                  onColorChanged: (color) {
                    timerService.updateSettings(backgroundColor: color.value);
                  },
                  labelTypes: const [],
                  pickerAreaHeightPercent: 0.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(TimerService timerService) async {
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

  void _showWhiteNoisePicker(BuildContext context, TimerService timerService, Function(String) onChanged) {
    final sounds = ['rain', 'forest', 'none'];
    final soundNames = {'rain': 'Rain', 'forest': 'Forest', 'none': 'None'};
    
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
                  const Text('Focus Sound', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    initialItem: sounds.contains(timerService.whiteNoiseSound) ? sounds.indexOf(timerService.whiteNoiseSound) : 0,
                  ),
                  onSelectedItemChanged: (int index) {
                    final selectedSound = sounds[index];
                    onChanged(selectedSound);
                    // No preview for white noise loop, it just plays if timer is running
                  },
                  children: sounds.map((s) => Center(child: Text(soundNames[s]!))).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    // Removed unused isDarkMode
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGlassTile({
    required BuildContext context,
    required Widget leading,
    required Widget title,
    Widget? trailing,
    Widget? additionalInfo,
    VoidCallback? onTap,
  }) {
    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Hit test
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced vertical padding
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12), // Reduced spacing
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 15, // Reduced title font size
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
                ),
                child: title,
              ),
            ),
            if (additionalInfo != null) ...[
              const SizedBox(width: 8),
              DefaultTextStyle(
                style: TextStyle(
                  color: isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 14, // Reduced info font size
                ),
                child: additionalInfo,
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      width: 28, // Reduced size
      height: 28, // Reduced size
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7), // Slightly tighter radius
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6, // Reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: CupertinoColors.white, size: 16), // Reduced icon size
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);
    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: RepaintBoundary( // Cache the static page for performance
        child: Stack(
          children: [
            // Background (blurred to match main app feel or just transparent to show desktop behind if possible, 
            // but here we likely want a solid but glass-like background for the settings page itself)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode ? [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF2d2d2d),
                  ] : [
                    const Color(0xFFf5f5f7),
                    const Color(0xFFe5e5ea),
                  ],
                ),
              ),
            ),
            
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Custom Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.back, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: '.SF Pro Display',
                            color: isDarkMode ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSectionHeader(context, 'Timer Duration'),
                        GlassContainer(
                          opacity: isDarkMode ? 0.15 : 0.05,
                          color: isDarkMode ? Colors.black : Colors.white,
                          blur: 20,
                          child: Column(
                            children: [
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.timer, CupertinoColors.systemBlue),
                                title: const Text('Focus'),
                                additionalInfo: Text('${timerService.focusMinutes} min'),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => _showPicker(
                                  context,
                                  'Focus Duration',
                                  timerService.focusMinutes,
                                  (val) => timerService.updateSettings(focus: val),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.pause, CupertinoColors.systemGreen),
                                title: const Text('Short Break'),
                                additionalInfo: Text('${timerService.shortBreakMinutes} min'),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => _showPicker(
                                  context,
                                  'Short Break',
                                  timerService.shortBreakMinutes,
                                  (val) => timerService.updateSettings(shortBreak: val),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.zzz, CupertinoColors.systemIndigo),
                                title: const Text('Long Break'),
                                additionalInfo: Text('${timerService.longBreakMinutes} min'),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => _showPicker(
                                  context,
                                  'Long Break',
                                  timerService.longBreakMinutes,
                                  (val) => timerService.updateSettings(longBreak: val),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildSectionHeader(context, 'Behavior'),
                        GlassContainer(
                          opacity: isDarkMode ? 0.15 : 0.05,
                          color: isDarkMode ? Colors.black : Colors.white,
                          blur: 20,
                          child: Column(
                            children: [
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.infinite, CupertinoColors.systemOrange),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Loop Mode'),
                                    Text(
                                      'Auto-start Focus/Breaks',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel.resolveFrom(context),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: timerService.loopMode,
                                    onChanged: (value) => timerService.updateSettings(loopMode: value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildSectionHeader(context, 'Sound & Notifications'),
                        GlassContainer(
                          opacity: isDarkMode ? 0.15 : 0.05,
                          color: isDarkMode ? Colors.black : Colors.white,
                          blur: 20,
                          child: Column(
                            children: [
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.volume_up, CupertinoColors.systemRed),
                                title: const Text('Tick Sound'),
                                trailing: Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: timerService.tickSound,
                                    onChanged: (value) => timerService.updateSettings(tickSound: value),
                                  ),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.speaker_2, CupertinoColors.systemPink),
                                title: const Text('Alarm Sound'),
                                additionalInfo: Text(timerService.alarmSound.toUpperCase()),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => _showSoundPicker(
                                  context,
                                  timerService,
                                  (val) => timerService.updateSettings(alarmSound: val),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.music_note_2, CupertinoColors.systemPurple),
                                title: const Text('Focus Sound'),
                                additionalInfo: Text(timerService.whiteNoiseSound.toUpperCase()),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => _showWhiteNoisePicker(
                                  context,
                                  timerService,
                                  (val) => timerService.updateSettings(whiteNoiseSound: val),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.bell, CupertinoColors.systemYellow),
                                title: const Text('Notifications'),
                                trailing: Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: timerService.enableNotifications,
                                    onChanged: (value) => timerService.updateSettings(enableNotifications: value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildSectionHeader(context, 'Appearance'),
                        GlassContainer(
                          opacity: isDarkMode ? 0.15 : 0.05,
                          color: isDarkMode ? Colors.black : Colors.white,
                          blur: 20,
                          child: Column(
                            children: [

                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.brightness, CupertinoColors.systemTeal),
                                title: const Text('Theme'),
                                trailing: SizedBox(
                                  width: 150,
                                  child: CupertinoSlidingSegmentedControl<String>(
                                    groupValue: timerService.themeMode,
                                    padding: const EdgeInsets.all(2),
                                    children: const {
                                      'system': Text('Auto', style: TextStyle(fontSize: 13)),
                                      'light': Text('Light', style: TextStyle(fontSize: 13)),
                                      'dark': Text('Dark', style: TextStyle(fontSize: 13)),
                                    },
                                    onValueChanged: (value) {
                                      if (value != null) {
                                        timerService.updateSettings(themeMode: value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.photo, CupertinoColors.systemPink),
                                title: const Text('Background'),
                                trailing: SizedBox(
                                  width: 150,
                                  child: CupertinoSlidingSegmentedControl<String>(
                                    groupValue: timerService.backgroundType,
                                    padding: const EdgeInsets.all(2),
                                    children: const {
                                      'default': Text('Default', style: TextStyle(fontSize: 13)),
                                      'color': Text('Color', style: TextStyle(fontSize: 13)),
                                      'image': Text('Image', style: TextStyle(fontSize: 13)),
                                    },
                                    onValueChanged: (value) {
                                      if (value != null) {
                                        timerService.updateSettings(backgroundType: value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              if (timerService.backgroundType == 'color') ...[
                                const Divider(height: 1, indent: 60, color: Colors.black12),
                                _buildGlassTile(
                                  context: context,
                                  leading: _buildIcon(CupertinoIcons.paintbrush, Color(timerService.backgroundColor)),
                                  title: const Text('Choose Color'),
                                  trailing: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Color(timerService.backgroundColor),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                                    ),
                                  ),
                                  onTap: () => _showColorPicker(context, timerService),
                                ),
                              ],
                              if (timerService.backgroundType == 'image') ...[
                                const Divider(height: 1, indent: 60, color: Colors.black12),
                                _buildGlassTile(
                                  context: context,
                                  leading: const Icon(CupertinoIcons.photo_on_rectangle, color: CupertinoColors.systemGrey),
                                  title: Text(
                                    timerService.backgroundImagePath.isEmpty 
                                        ? 'Select Image' 
                                        : 'Change Image',
                                  ),
                                  additionalInfo: timerService.backgroundImagePath.isNotEmpty 
                                      ? SizedBox(
                                          width: 60, 
                                          child: Text(
                                            timerService.backgroundImagePath.split('/').last,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        )
                                      : null,
                                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                  onTap: () => _pickImage(timerService),
                                ),
                              ],
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              _buildGlassTile(
                                context: context,
                                leading: _buildIcon(CupertinoIcons.layers, CupertinoColors.systemPurple),
                                title: const Text('Always on Top'),
                                trailing: Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: timerService.alwaysOnTop,
                                    onChanged: (value) => timerService.updateSettings(alwaysOnTop: value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        Center(
                          child: Text(
                            'PomoFlow ${const String.fromEnvironment('APP_VERSION', defaultValue: 'v0.0.1')}',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}