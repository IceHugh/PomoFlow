import 'dart:math';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'timer_service.dart';
import 'settings_page.dart';
import 'package:window_manager/window_manager.dart';
import 'widgets/glass_container.dart';

class PomodoroTimerPage extends StatelessWidget {
  const PomodoroTimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          const _TimerBackground(),
          const _BackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final shortSide = min(constraints.maxWidth, constraints.maxHeight);
                      final circleSize = shortSide * 0.50;

                      return Center(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 10),
                                _TimerDisplay(circleSize: circleSize),
                                const SizedBox(height: 30),
                                const _TimerControls(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: SizedBox(
        height: 40,
        child: DragToMoveArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Opacity(
                opacity: context.select<TimerService, double>((s) => s.uiOpacity),
                child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(50),
                  blur: context.select<TimerService, String>((s) => s.backgroundType) == 'image' ? 0 : 15,
                  opacity: 0.1,
                  color: Color(context.select<TimerService, int>((s) => s.contentColor)),
                  border: Border.all(color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.2), width: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(CupertinoIcons.settings, size: 20, color: Color(context.select<TimerService, int>((s) => s.contentColor))),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0); // Slide from bottom
                        const end = Offset.zero;
                        const curve = Curves.easeOutQuart;

                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: FadeTransition(
                            opacity: animation, 
                            child: child
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 600),
                    ),
                  );
                },
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerBackground extends StatelessWidget {
  const _TimerBackground();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Selector<TimerService, TimerMode>(
      selector: (_, service) => service.currentMode,
      builder: (context, currentMode, child) {
        final timerService = Provider.of<TimerService>(context);
        
        if (timerService.backgroundType == 'color') {
          return Container(
            color: Color(timerService.backgroundColor),
          );
        } else if (timerService.backgroundType == 'image' && timerService.backgroundImagePath.isNotEmpty) {
           return Stack(
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
               // The Image with fade-in
               Image.file(
                 File(timerService.backgroundImagePath),
                 fit: BoxFit.cover,
                 width: double.infinity,
                 height: double.infinity,
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

class _BackgroundOrbs extends StatelessWidget {
  const _BackgroundOrbs();

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

class _TimerDisplay extends StatelessWidget {
  final double circleSize;

  const _TimerDisplay({required this.circleSize});

  void _showTimerPicker(BuildContext context, TimerService timerService) {
      int initialValue;
      String title;
      Function(int) onChanged;

      switch (timerService.currentMode) {
        case TimerMode.focus:
          initialValue = timerService.focusMinutes;
          title = 'Focus Duration';
          onChanged = (val) => timerService.updateSettings(focus: val);
          break;
        case TimerMode.shortBreak:
          initialValue = timerService.shortBreakMinutes;
          title = 'Short Break Duration';
          onChanged = (val) => timerService.updateSettings(shortBreak: val);
          break;
        case TimerMode.longBreak:
          initialValue = timerService.longBreakMinutes;
          title = 'Long Break Duration';
          onChanged = (val) => timerService.updateSettings(longBreak: val);
          break;
      }

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // GROUP A: Static Background (Cached)
        Opacity(
          opacity: context.select<TimerService, double>((s) => s.uiOpacity),
          child: RepaintBoundary(
            child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Background Glow
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              
              // 2. Glass Disc (No child content)
              GlassContainer(
                width: circleSize,
                height: circleSize,
                borderRadius: BorderRadius.circular(circleSize),
                blur: context.select<TimerService, String>((s) => s.backgroundType) == 'image' ? 0 : 25,
                opacity: 0.12,
                color: Color(context.select<TimerService, int>((s) => s.contentColor)),
                border: Border.all(
                  color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
        ),


        // GROUP B: Dynamic Foreground (Isolated)
        RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 3. Progress Ring
              Opacity(
                opacity: context.select<TimerService, double>((s) => s.uiOpacity),
                child: SizedBox(
                  width: circleSize + 20,
                height: circleSize + 20,
                child: Selector<TimerService, double>(
                  selector: (_, service) => service.progress,
                  builder: (context, progress, child) {
                    return CustomPaint(
                      painter: ProgressPainter(
                        progress: progress,
                        color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.9),
                        trackColor: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.1),
                      ),
                    );
                  },
                ),
              ),
              ),

              // 4. Text & Status
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Time
                    Selector<TimerService, String>(
                      selector: (_, service) => service.formattedTime,
                      builder: (context, formattedTime, child) {
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showTimerPicker(context, context.read<TimerService>());
                          },
                          child: Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: circleSize * 0.28,
                              fontWeight: FontWeight.w200,
                              fontFamily: context.select<TimerService, String>((s) => s.fontFamily) == 'system' 
                                  ? '.SF Pro Display' 
                                  : context.select<TimerService, String>((s) => s.fontFamily),
                              letterSpacing: -2.0,
                              color: Color(context.select<TimerService, int>((s) => s.contentColor)),
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                        );
                      }
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: context.select<TimerService, double>((s) => s.uiOpacity),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        // Reset
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.read<TimerService>().resetTimer();
          },
          child: GlassContainer(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(30),
            blur: context.select<TimerService, String>((s) => s.backgroundType) == 'image' ? 0 : 15,
            opacity: 0.15,
            color: Color(context.select<TimerService, int>((s) => s.contentColor)),
            alignment: Alignment.center,
            border: Border.all(color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.3), width: 1),
            child: Icon(CupertinoIcons.restart, color: Color(context.select<TimerService, int>((s) => s.contentColor)), size: 24),
          ),
        ),
        const SizedBox(width: 30),
        // Play/Pause
        Selector<TimerService, bool>(
          selector: (_, service) => service.isRunning,
          builder: (context, isRunning, child) {
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.selectionClick();
                context.read<TimerService>().toggleTimer();
              },
              child: GlassContainer(
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(40),
                blur: context.select<TimerService, String>((s) => s.backgroundType) == 'image' ? 0 : 20,
                opacity: 0.25,
                color: Color(context.select<TimerService, int>((s) => s.contentColor)),
                alignment: Alignment.center,
                border: Border.all(color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.6), width: 1),
                child: Icon(
                  isRunning ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                  color: Color(context.select<TimerService, int>((s) => s.contentColor)),
                  size: 40,
                ),
              ),
            );
          }
        ),
        const SizedBox(width: 30),
        // Skip
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.read<TimerService>().skip();
          },
          child: GlassContainer(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(30),
            blur: context.select<TimerService, String>((s) => s.backgroundType) == 'image' ? 0 : 15,
            opacity: 0.15,
            color: Color(context.select<TimerService, int>((s) => s.contentColor)),
            alignment: Alignment.center,
            border: Border.all(color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.3), width: 1),
            child: Icon(CupertinoIcons.forward_end_fill, color: Color(context.select<TimerService, int>((s) => s.contentColor)), size: 24),
          ),
        ),
      ],
      ),
    );
  }
}

class ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  ProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 5.0;

    // Background Circle
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc starting from top (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.trackColor != trackColor;
  }
}