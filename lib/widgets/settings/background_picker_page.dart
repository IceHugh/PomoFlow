import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../timer_service.dart';

/// Show background image picker as bottom sheet
void showBackgroundImagePicker(BuildContext context) {
  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) => const _BackgroundPickerSheet(),
  );
}

class _BackgroundPickerSheet extends StatefulWidget {
  const _BackgroundPickerSheet();

  @override
  State<_BackgroundPickerSheet> createState() => _BackgroundPickerSheetState();
}

class _BackgroundPickerSheetState extends State<_BackgroundPickerSheet> {
  bool _isLoading = false;

  Future<void> _pickImage(TimerService timerService) async {
    try {
      setState(() => _isLoading = true);
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await timerService.addBackgroundImage(result.files.single.path!);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(e.toString().contains('Maximum')
                ? 'Maximum of 10 images allowed'
                : 'Failed to add image: $e'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteImage(TimerService timerService, String id, String name) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Image'),
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
        await timerService.deleteBackgroundImage(id);
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete image: $e'),
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        final backgroundImages = timerService.backgroundImages;
        final selectedCount = backgroundImages.where((img) => img.isSelected).length;

        return Container(
          height: screenHeight * 0.7, // 70% of screen height
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
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Background Images',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                          ),
                        ),
                        if (selectedCount > 0)
                          Text(
                            '$selectedCount selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 60), // Balance the layout
                  ],
                ),
              ),

              // Carousel Settings
              if (selectedCount > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Carousel Interval', 
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          Text(
                            '${timerService.backgroundCarouselInterval}s', 
                            style: const TextStyle(
                              fontSize: 14, 
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlider(
                          value: timerService.backgroundCarouselInterval.toDouble().clamp(5.0, 60.0),
                          min: 5.0,
                          max: 60.0,
                          divisions: 55,
                          activeColor: CupertinoColors.activeBlue,
                          onChanged: (value) {
                            timerService.updateSettings(backgroundCarouselInterval: value.round());
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Grid Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator(radius: 16))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: backgroundImages.length + 1, // +1 for add button
                        itemBuilder: (context, index) {
                          // Add button as last item
                          if (index == backgroundImages.length) {
                            return _AddImageCard(
                              isDarkMode: isDarkMode,
                              onTap: () => _pickImage(timerService),
                            );
                          }

                          final image = backgroundImages[index];
                          return _ImageCard(
                            image: image,
                            isDarkMode: isDarkMode,
                            onTap: () => timerService.toggleBackgroundImageSelection(image.id),
                            onDelete: () => _deleteImage(timerService, image.id, image.name),
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

class _ImageCard extends StatelessWidget {
  final dynamic image; // BackgroundImage
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ImageCard({
    required this.image,
    required this.isDarkMode,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = image.isSelected as bool;
    
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Animated container for selection effect
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(isSelected ? 3.0 : 0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? CupertinoColors.activeBlue : Colors.transparent,
                width: isSelected ? 2.0 : 0.0,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(image.filePath as String),
                      fit: BoxFit.cover,
                      cacheWidth: 300, // Slightly larger for better quality
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                          child: Icon(
                            CupertinoIcons.photo,
                            color: isDarkMode ? Colors.white24 : Colors.black26,
                          ),
                        );
                      },
                    ),
                    // Selection overlay
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 0.3 : 0.0,
                      child: Container(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Delete button (Top Right)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.black : Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageCard extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onTap;

  const _AddImageCard({
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.03),
          border: Border.all(
            color: isDarkMode 
                ? Colors.white.withValues(alpha: 0.1) 
                : Colors.black.withValues(alpha: 0.05),
            width: 1.5,
          ), 
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.white,
                boxShadow: isDarkMode ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.plus,
                size: 24,
                color: isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
