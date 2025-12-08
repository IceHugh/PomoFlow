import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../glass_container.dart';
import '../../timer_service.dart';

/// Sound type enumeration
enum SoundType {
  none,      // No sound option
  builtin,   // Built-in sound
  custom,    // Custom sound
  add,       // Add button
}

/// Sound item data model
class SoundItem {
  final String id;
  final String name;
  final IconData icon;
  final SoundType type;

  const SoundItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });
}

/// Show sound picker as bottom sheet modal
void showSoundPicker({
  required BuildContext context,
  required String title,
  required List<SoundItem> Function() getSoundItems,
  required String Function() getCurrentSelection,
  required Function(String id) onSelect,
  Function(String id, String name)? onDelete,
  bool isLoading = false,
  bool isAmbientSound = false, // Flag to distinguish ambient sounds
}) {
  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) => _SoundPickerSheet(
      title: title,
      getSoundItems: getSoundItems,
      getCurrentSelection: getCurrentSelection,
      onSelect: onSelect,
      onDelete: onDelete,
      isLoading: isLoading,
      isAmbientSound: isAmbientSound,
    ),
  );
}

class _SoundPickerSheet extends StatefulWidget {
  final String title;
  final List<SoundItem> Function() getSoundItems;
  final String Function() getCurrentSelection;
  final Function(String id) onSelect;
  final Function(String id, String name)? onDelete;
  final bool isLoading;
  final bool isAmbientSound;

  const _SoundPickerSheet({
    required this.title,
    required this.getSoundItems,
    required this.getCurrentSelection,
    required this.onSelect,
    this.onDelete,
    this.isLoading = false,
    this.isAmbientSound = false,
  });

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  final AudioPlayer _previewPlayer = AudioPlayer();
  Timer? _stopTimer;
  String? _currentPreviewId;

  @override
  void dispose() {
    _stopPreview();
    _previewPlayer.dispose();
    super.dispose();
  }

  void _stopPreview() {
    _stopTimer?.cancel();
    _stopTimer = null;
    _previewPlayer.stop();
    _currentPreviewId = null;
  }

  Future<void> _playPreview(String id, String name) async {
    // Don't preview 'none' or 'add'
    if (id == 'none' || id == 'add') return;

    // Stop any current preview
    _stopPreview();
    _currentPreviewId = id;

    try {
      final timerService = Provider.of<TimerService>(context, listen: false);

      if (widget.isAmbientSound) {
        // Ambient sound preview
        if (id == 'rain' || id == 'forest') {
          // Built-in ambient sounds
          await _previewPlayer.play(AssetSource('sounds/ambient/$id.mp3'));
        } else {
          // Custom ambient sound
          final customSound = timerService.customAmbientSounds.firstWhere(
            (s) => s.id == id,
            orElse: () => throw Exception('Sound not found'),
          );
          await _previewPlayer.play(DeviceFileSource(customSound.filePath));
        }
        
        // Stop after 5 seconds for ambient sounds
        _stopTimer = Timer(const Duration(seconds: 5), () {
          if (_currentPreviewId == id) {
            _stopPreview();
          }
        });
      } else {
        // Alarm sound preview (plays once)
        if (id == 'bell' || id == 'digital') {
          // Built-in alarm sounds
          String fileName = id == 'bell' ? 'alarms/bell.mp3' : 'alarms/digital.mp3';
          await _previewPlayer.play(AssetSource('sounds/$fileName'));
        } else {
          // Custom alarm sound
          final customSound = timerService.customAlarmSounds.firstWhere(
            (s) => s.id == id,
            orElse: () => throw Exception('Sound not found'),
          );
          await _previewPlayer.play(DeviceFileSource(customSound.filePath));
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error playing preview: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        final soundItems = widget.getSoundItems();
        final currentSelection = widget.getCurrentSelection();

        return Container(
          height: screenHeight * 0.65, // 65% of screen height
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1c1c1e) : CupertinoColors.systemBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                const SizedBox(width: 60), // Balance the layout
              ],
            ),
          ),

          // Grid Content
          Expanded(
            child: widget.isLoading
                ? const Center(child: CupertinoActivityIndicator(radius: 16))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: soundItems.length,
                    itemBuilder: (context, index) {
                      final item = soundItems[index];
                      final isSelected = currentSelection == item.id;
                      final isAdd = item.type == SoundType.add;

                      return _SoundCard(
                        name: item.name,
                        icon: item.icon,
                        isSelected: isSelected,
                        isAdd: isAdd,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          // Play preview before selecting
                          _playPreview(item.id, item.name);
                          // Call the original onSelect
                          widget.onSelect(item.id);
                        },
                        onDelete: widget.onDelete != null && item.id != 'none' && item.id != 'add'
                            ? () => widget.onDelete!(item.id, item.name)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _SoundCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final bool isAdd;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SoundCard({
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.isAdd,
    required this.isDarkMode,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_SoundCard> createState() => _SoundCardState();
}

class _SoundCardState extends State<_SoundCard> with SingleTickerProviderStateMixin {
  late AnimationController _scrollController;
  late Animation<double> _scrollAnimation;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scrollAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scrollController, curve: Curves.linear),
    );

    // Check if text needs scrolling after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsScroll();
    });
  }

  void _checkIfNeedsScroll() {
    // Simple heuristic: if name is longer than 12 characters, enable scrolling
    String displayName = widget.name;
    if (!widget.isAdd && widget.name.contains('.')) {
      displayName = widget.name.substring(0, widget.name.lastIndexOf('.'));
    }
    
    if (displayName.length > 12) {
      setState(() => _needsScroll = true);
      _startScrolling();
    }
  }

  void _startScrolling() {
    _scrollController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = CupertinoColors.activeBlue;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

    // Process filename: remove extension
    String displayName = widget.name;
    if (!widget.isAdd && widget.name.contains('.')) {
      displayName = widget.name.substring(0, widget.name.lastIndexOf('.'));
    }

    // Determine colors
    final Color cardColor = widget.isSelected ? themeColor : Colors.white;
    final double opacity = widget.isSelected ? 0.2 : (widget.isDarkMode ? 0.1 : 0.6);
    final Color iconColor = widget.isAdd
        ? (widget.isDarkMode ? Colors.white70 : Colors.black54)
        : (widget.isSelected ? themeColor : (widget.isDarkMode ? Colors.white70 : Colors.black54));
    final Color iconBgColor = widget.isAdd 
        ? (widget.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
        : (widget.isSelected ? themeColor.withValues(alpha: 0.2) : Colors.transparent);
    final Color borderColor = widget.isSelected 
        ? themeColor.withValues(alpha: 0.5) 
        : (widget.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05));

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          // Card Body
          GlassContainer(
            borderRadius: BorderRadius.circular(20),
            opacity: opacity,
            color: cardColor,
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 2 : 1,
            ),
            blur: 20,
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: iconBgColor,
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                       widget.icon,
                       size: 26,
                       color: iconColor,
                     ),
                   ),
                   const SizedBox(height: 8),
                   // Scrolling text container
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 4),
                     child: SizedBox(
                       height: 14, // Fixed height for single line
                       child: _needsScroll
                           ? AnimatedBuilder(
                               animation: _scrollAnimation,
                               builder: (context, child) {
                                 return ClipRect(
                                   child: Align(
                                     alignment: Alignment(
                                       _scrollAnimation.value * 2 - 1, // -1 to 1
                                       0,
                                     ),
                                     widthFactor: 1.0,
                                     child: Text(
                                       displayName,
                                       maxLines: 1,
                                       overflow: TextOverflow.visible,
                                       textAlign: TextAlign.center,
                                       style: TextStyle(
                                         fontSize: 11,
                                         fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                                         color: widget.isSelected 
                                             ? themeColor 
                                             : textColor.withValues(alpha: 0.8),
                                       ),
                                     ),
                                   ),
                                 );
                               },
                             )
                           : Text(
                               displayName,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                               textAlign: TextAlign.center,
                               style: TextStyle(
                                 fontSize: 11,
                                 fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                                 color: widget.isSelected 
                                     ? themeColor 
                                     : textColor.withValues(alpha: 0.8),
                               ),
                             ),
                     ),
                   ),
                ],
              ),
            ),
          ),

          // Delete Button
          if (widget.onDelete != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.destructiveRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.destructiveRed.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.minus,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
