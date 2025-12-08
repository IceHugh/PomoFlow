import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timer_service.dart';
import 'widgets/glass_container.dart';
import 'widgets/settings/glass_tile.dart';
import 'widgets/settings/settings_pickers.dart';
import 'widgets/settings/ambient_sound_picker_page.dart';
import 'widgets/settings/alarm_sound_picker_page.dart';
import 'widgets/settings/background_picker_page.dart';
import 'main.dart' show appVersion;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getAmbientSoundName(TimerService timerService) {
    final soundId = timerService.whiteNoiseSound;
    
    // Built-in sounds
    if (soundId == 'none') return 'None';
    if (soundId == 'brook') return 'Brook';
    if (soundId == 'ocean') return 'Ocean';
    if (soundId == 'rain') return 'Rain';
    
    // Custom sounds
    try {
      final customSound = timerService.customAmbientSounds.firstWhere(
        (s) => s.id == soundId,
      );
      // Truncate long file names
      final name = customSound.name;
      return name.length > 15 ? '${name.substring(0, 12)}...' : name;
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);
    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: RepaintBoundary(
        child: Stack(
          children: [
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
                            fontSize: 20,
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
                        _buildSectionHeader(context, 'Timer'),
                        GlassContainer(
                          opacity: isDarkMode ? 0.15 : 0.05,
                          color: isDarkMode ? Colors.black : Colors.white,
                          blur: 20,
                          child: Column(
                            children: [
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.timer, color: CupertinoColors.systemBlue),
                                title: const Text('Focus'),
                                additionalInfo: Text('${timerService.focusMinutes} min'),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => SettingsPickers.showPicker(
                                  context,
                                  'Focus Duration',
                                  timerService.focusMinutes,
                                  (val) => timerService.updateSettings(focus: val),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.pause, color: CupertinoColors.systemGreen),
                                title: const Text('Short Break'),
                                additionalInfo: Text('${timerService.shortBreakMinutes} min'),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => SettingsPickers.showPicker(
                                  context,
                                  'Short Break',
                                  timerService.shortBreakMinutes,
                                  (val) => timerService.updateSettings(shortBreak: val),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.zzz, color: CupertinoColors.systemIndigo),
                                title: const Text('Long Break'),
                                additionalInfo: Text('${timerService.longBreakMinutes} min'),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => SettingsPickers.showPicker(
                                  context,
                                  'Long Break',
                                  timerService.longBreakMinutes,
                                  (val) => timerService.updateSettings(longBreak: val),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.infinite, color: CupertinoColors.systemOrange),
                                title: const Text('Auto-start'),
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

                        _buildSectionHeader(context, 'Appearance'),
                        GlassContainer(
                          opacity: isDarkMode ? 0.15 : 0.05,
                          color: isDarkMode ? Colors.black : Colors.white,
                          blur: 20,
                          child: Column(
                            children: [
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.brightness, color: CupertinoColors.systemTeal),
                                title: const Text('Theme'),
                                trailing: SizedBox(
                                  width: 150,
                                  child: CupertinoSlidingSegmentedControl<String>(
                                    groupValue: timerService.themeMode,
                                    padding: const EdgeInsets.all(2),
                                    children: const {
                                      'system': Text('Auto', style: TextStyle(fontSize: 12)),
                                      'light': Text('Light', style: TextStyle(fontSize: 12)),
                                      'dark': Text('Dark', style: TextStyle(fontSize: 12)),
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
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.rectangle_grid_1x2, color: CupertinoColors.systemIndigo),
                                title: const Text('View Style'),
                                trailing: SizedBox(
                                  width: 150,
                                  child: CupertinoSlidingSegmentedControl<String>(
                                    groupValue: timerService.layoutMode,
                                    padding: const EdgeInsets.all(2),
                                    children: const {
                                      'default': Text('Default', style: TextStyle(fontSize: 12)),
                                      'gallery': Text('Gallery', style: TextStyle(fontSize: 12)),
                                    },
                                    onValueChanged: (value) {
                                      if (value != null) {
                                        timerService.updateSettings(layoutMode: value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.photo, color: CupertinoColors.systemPink),
                                title: const Text('Background Type'),
                                trailing: SizedBox(
                                  width: 180,
                                  child: CupertinoSlidingSegmentedControl<String>(
                                    groupValue: timerService.backgroundType,
                                    padding: const EdgeInsets.all(2),
                                    children: const {
                                      'default': Text('Default', style: TextStyle(fontSize: 12)),
                                      'color': Text('Color', style: TextStyle(fontSize: 12)),
                                      'image': Text('Image', style: TextStyle(fontSize: 12)),
                                    },
                                    onValueChanged: (value) {
                                      if (value != null) {
                                        timerService.updateSettings(backgroundType: value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              if (timerService.backgroundType == 'image') ...[ 
                                const Divider(height: 1, indent: 60, color: Colors.black12),
                                GlassTile(
                                  leading: const SettingsIcon(icon: CupertinoIcons.photo_fill_on_rectangle_fill, color: CupertinoColors.systemBlue),
                                  title: const Text('Manage Images'),
                                  additionalInfo: Text(
                                    timerService.selectedBackgroundImages.isEmpty 
                                        ? 'No images' 
                                        : '${timerService.selectedBackgroundImages.length} selected',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                  onTap: () => showBackgroundImagePicker(context),
                                ),
                              ],
                              if (timerService.backgroundType == 'color') ...[
                                const Divider(height: 1, indent: 60, color: Colors.black12),
                                GlassTile(
                                  leading: SettingsIcon(icon: CupertinoIcons.paintbrush, color: Color(timerService.backgroundColor)),
                                  title: const Text('Color'),
                                  trailing: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Color(timerService.backgroundColor),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                  onTap: () => SettingsPickers.showColorPicker(context, timerService),
                                ),
                              ],
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              GlassTile(
                                leading: SettingsIcon(icon: CupertinoIcons.eyedropper, color: Color(timerService.contentColor)),
                                title: const Text('Tint Color'),
                                trailing: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Color(timerService.contentColor),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                                  ),
                                ),
                                onTap: () => SettingsPickers.showContentColorPicker(context, timerService),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              GlassTile(
                                leading: SettingsIcon(icon: CupertinoIcons.textformat_size, color: Color(timerService.contentColor)),
                                title: const Text('Font'),
                                additionalInfo: Text(timerService.fontFamily == 'system' ? 'System Default' : timerService.fontFamily),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => SettingsPickers.showFontPicker(context, timerService),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    const SettingsIcon(icon: CupertinoIcons.eye, color: CupertinoColors.systemCyan),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Opacity',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: isDarkMode ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12.0),
                                        child: CupertinoSlider(
                                          value: timerService.uiOpacity,
                                          min: 0.2,
                                          max: 1.0,
                                          onChanged: (value) => timerService.updateSettings(uiOpacity: value),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildSectionHeader(context, 'Sounds'),
                        GlassContainer(
                          opacity: isDarkMode ? 0.15 : 0.05,
                          color: isDarkMode ? Colors.black : Colors.white,
                          blur: 20,
                          child: Column(
                            children: [
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.volume_up, color: CupertinoColors.systemRed),
                                title: const Text('Ticking'),
                                trailing: Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: timerService.tickSound,
                                    onChanged: (value) => timerService.updateSettings(tickSound: value),
                                  ),
                                ),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.speaker_2, color: CupertinoColors.systemPink),
                                title: const Text('Alarm'),
                                additionalInfo: Text(timerService.alarmSound.toUpperCase()),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => showAlarmSoundPicker(context),
                              ),
                              const Divider(height: 1, indent: 60, color: Colors.black12),
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.music_note_2, color: CupertinoColors.systemPurple),
                                title: const Text('Ambient'),
                                additionalInfo: Text(_getAmbientSoundName(timerService)),
                                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.systemGrey3),
                                onTap: () => showAmbientSoundPicker(context),
                              ),
                            ],
                          ),
                        ),

                        _buildSectionHeader(context, 'System'),
                        GlassContainer(
                          opacity: isDarkMode ? 0.15 : 0.05,
                          color: isDarkMode ? Colors.black : Colors.white,
                          blur: 20,
                          child: Column(
                            children: [
                              GlassTile(
                                leading: const SettingsIcon(icon: CupertinoIcons.bell, color: CupertinoColors.systemYellow),
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

                        const SizedBox(height: 30),
                        Center(
                          child: Text(
                            'Rhei $appVersion',
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