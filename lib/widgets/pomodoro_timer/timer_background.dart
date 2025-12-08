
import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../timer_service.dart';

class TimerBackground extends StatefulWidget {
  const TimerBackground({super.key});

  @override
  State<TimerBackground> createState() => _TimerBackgroundState();
}

class _TimerBackgroundState extends State<TimerBackground> {
  Timer? _carouselTimer;
  int _currentImageIndex = 0;
  String? _currentImagePath;
  String? _nextImagePath;
  bool _showNext = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCarousel();
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _initializeCarousel() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    final selectedImages = timerService.selectedBackgroundImages;

    if (selectedImages.isEmpty) {
      _currentImagePath = null;
      return;
    }

    // Set initial image
    _currentImagePath = selectedImages[0].filePath;
    _currentImageIndex = 0;

    // Start carousel if multiple images
    if (selectedImages.length > 1) {
      _startCarousel();
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    
    final timerService = Provider.of<TimerService>(context, listen: false);
    final interval = timerService.backgroundCarouselInterval;
    
    // Schedule next image change
    void scheduleNext() {
      if (!mounted) return;
      
      final selectedImages = timerService.selectedBackgroundImages;
      if (selectedImages.length <= 1) {
        _carouselTimer?.cancel();
        return;
      }

      // Wait for the display interval, then start transition
      _carouselTimer = Timer(Duration(seconds: interval), () {
        if (!mounted) return;
        
        // Move to next image
        _currentImageIndex = (_currentImageIndex + 1) % selectedImages.length;
        _nextImagePath = selectedImages[_currentImageIndex].filePath;

        // Trigger fade transition
        setState(() {
          _showNext = true;
        });

        // After transition animation completes, update current and schedule next
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _currentImagePath = _nextImagePath;
              _showNext = false;
              _nextImagePath = null;
            });
            // Schedule the next change (interval doesn't include animation time)
            scheduleNext();
          }
        });
      });
    }
    
    // Start the carousel
    scheduleNext();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Selector<TimerService, TimerMode>(
      selector: (_, service) => service.currentMode,
      builder: (context, currentMode, child) {
        final timerService = Provider.of<TimerService>(context);
        
        // Update carousel when selected images change
        final selectedImages = timerService.selectedBackgroundImages;
        if (selectedImages.isNotEmpty && _currentImagePath == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeCarousel();
          });
        } else if (selectedImages.isEmpty && _currentImagePath != null) {
          _currentImagePath = null;
          _carouselTimer?.cancel();
        }
        
        if (timerService.backgroundType == 'color') {
          return Container(
            color: Color(timerService.backgroundColor),
          );
        } else if (timerService.backgroundType == 'image') {
          // Use carousel images if available
          if (selectedImages.isNotEmpty && _currentImagePath != null) {
            return RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fallback Gradient while loading
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode 
                           ? [const Color(0xFF2E3192), const Color(0xFF1BFFFF)]
                           : [const Color(0xFFA1C4FD), const Color(0xFFC2E9FB)],
                      ),
                    ),
                  ),
                  
                  // Current Image
                  Image.file(
                    File(_currentImagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    cacheWidth: 810, // 2x window width (405 * 2) for Retina displays
                    errorBuilder: (ctx, err, stack) => Container(color: Colors.black),
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                  ),
                  
                  // Next Image (crossfade transition)
                  if (_showNext && _nextImagePath != null)
                    AnimatedOpacity(
                      opacity: _showNext ? 1 : 0,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      child: Image.file(
                        File(_nextImagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: 810, // 2x window width for Retina
                        errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            );
          }
          
          // Fallback to old single image path if no carousel images
          if (timerService.backgroundImagePath.isNotEmpty) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode 
                         ? [const Color(0xFF2E3192), const Color(0xFF1BFFFF)]
                         : [const Color(0xFFA1C4FD), const Color(0xFFC2E9FB)],
                    ),
                  ),
                ),
                Image.file(
                  File(timerService.backgroundImagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth: 810, // 2x window width for Retina
                  errorBuilder: (ctx, err, stack) => Container(color: Colors.black),
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                ),
              ],
            );
          }
        }

        // Default gradient background
        Color bgTop, bgBottom;
        if (currentMode == TimerMode.focus) {
          bgTop = isDarkMode ? const Color(0xFF2E3192) : const Color(0xFFA1C4FD);
          bgBottom = isDarkMode ? const Color(0xFF1BFFFF) : const Color(0xFFC2E9FB);
        } else {
          bgTop = isDarkMode ? const Color(0xFF0ba360) : const Color(0xFF84fab0);
          bgBottom = isDarkMode ? const Color(0xFF3cba92) : const Color(0xFF8fd3f4);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgTop, bgBottom],
            ),
          ),
        );
      },
    );
  }
}

class BackgroundOrbs extends StatelessWidget {
  const BackgroundOrbs({super.key});

  @override

  Widget build(BuildContext context) {
    final backgroundType = context.select<TimerService, String>((s) => s.backgroundType);
    if (backgroundType != 'default') {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purpleAccent.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blueAccent.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
