import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../timer_service.dart';
import '../glass_container.dart';

class ImmersiveBreakOverlay extends StatelessWidget {
  const ImmersiveBreakOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);
    final isFocusing = timerService.currentMode == TimerMode.focus;

    // Safety check: if focusing, we shouldn't be here typically, 
    // but the parent might control visibility.
    if (isFocusing) return const SizedBox.shrink();

    return Container(
      color: Colors.transparent, // Allow background to show through
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spacer to push content slightly up if needed, or just center
            
            // Mode Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                timerService.currentMode == TimerMode.shortBreak ? 'Short Break' : 'Long Break',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Large Timer
            Text(
              timerService.formattedTime,
              style: const TextStyle(
                fontSize: 120, // Very large
                fontWeight: FontWeight.w200,
                color: Colors.white,
                fontFamily: '.SF Pro Display',
                height: 1.0,
              ),
            ),
            
            const SizedBox(height: 60),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stop/Skip Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.forward_end_fill, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onPressed: () {
                    timerService.skip();
                  },
                ),
                
                const SizedBox(width: 24),

                // Exit Fullscreen Button (Safety hatch)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(
                      CupertinoIcons.fullscreen_exit, 
                      color: Colors.white, 
                      size: 24
                    ),
                  ),
                  onPressed: () async {
                    await windowManager.setFullScreen(false);
                    // The main layout will likely update on next frame if we are listening to window state properly,
                    // or if the window state change triggers a rebuild.
                    // However, our logic relies on `fullscreenBreakOnDesktop` setting currently.
                    // If user manually exits fullscreen, we might want to respect that state.
                    // But for now, just exiting fullscreen is a good manual override.
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
