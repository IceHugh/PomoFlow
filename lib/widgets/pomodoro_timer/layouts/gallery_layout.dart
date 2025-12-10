

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../timer_service.dart';
import '../top_bar.dart';
import 'gallery_controls.dart';
import '../timer_picker_sheet.dart';
import '../cycle_indicator.dart';

class GalleryLayout extends StatelessWidget {
  const GalleryLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const TopBar(),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time Display
                  Selector<TimerService, String>(
                    selector: (_, service) => service.formattedTime,
                    builder: (context, formattedTime, child) {
                      return GestureDetector(
                        onTap: () {
                          // HapticFeedback.selectionClick();
                          showTimerPickerSheet(context, context.read<TimerService>());
                        },
                        child: Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w200,
                            fontFamily: context.select<TimerService, String>((s) => s.fontFamily) == 'system' 
                                ? '.SF Pro Display' 
                                : context.select<TimerService, String>((s) => s.fontFamily),
                            letterSpacing: -1.0,
                            color: Color(context.select<TimerService, int>((s) => s.contentColor)),
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar
                  Selector<TimerService, double>(
                    selector: (_, service) => service.progress,
                    builder: (context, progress, child) {
                      return Opacity(
                        opacity: context.select<TimerService, double>((s) => s.uiOpacity),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.8),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Center(child: CycleIndicator()),
                  const SizedBox(height: 16),
                  // Controls (Scaled down slightly if needed, or normal)
                  // Using Transform.scale to make it slightly more compact if 'very low' height is needed
                  const GalleryControls(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
