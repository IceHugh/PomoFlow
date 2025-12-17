
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'dart:io';
import 'widgets/pomodoro_timer/timer_background.dart';
import 'widgets/pomodoro_timer/layouts/default_layout.dart';
import 'widgets/pomodoro_timer/layouts/gallery_layout.dart';
import 'widgets/pomodoro_timer/immersive_break_overlay.dart';
import 'timer_service.dart'; // Ensure TimerService is imported for Selector

class PomodoroTimerPage extends StatelessWidget {
  const PomodoroTimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          const TimerBackground(),
          const BackgroundOrbs(),
          // Main UI Layer - Fade out when immersive
          Selector<TimerService, (String, bool, TimerMode)>(
            selector: (_, service) => (
              service.layoutMode, 
              service.fullscreenBreakOnDesktop,
              service.currentMode
            ),
            builder: (context, data, child) {
              final layoutMode = data.$1;
              final fullscreenBreak = data.$2;
              final mode = data.$3;
              
              // Helper to determine if we should show immersive UI
              // This is a simplified check. For perfect sync with actual window state,
              // we'd need to listen to window events. For now, we trust the setting + mode logic.
              // We only show immersive if specific setting is ON and we are in a break.
              bool isImmersive = false;
              if (Platform.isMacOS || Platform.isWindows) {
                 if (fullscreenBreak && mode != TimerMode.focus) {
                   isImmersive = true;
                 }
              }

              return Stack(
                children: [
                   AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isImmersive ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: isImmersive,
                      child: SafeArea(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: layoutMode == 'gallery' 
                              ? const GalleryLayout()
                              : const DefaultLayout(),
                        ),
                      ),
                    ),
                  ),
                  
                  // Immersive Overlay
                  if (isImmersive)
                    const Positioned.fill(
                      child: ImmersiveBreakOverlay(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}