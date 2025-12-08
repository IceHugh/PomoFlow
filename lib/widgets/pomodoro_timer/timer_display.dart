


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../timer_service.dart';
import '../glass_container.dart';
import 'progress_painter.dart';
import 'timer_picker_sheet.dart';

class TimerDisplay extends StatelessWidget {
  final double circleSize;

  const TimerDisplay({super.key, required this.circleSize});
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
                    return RepaintBoundary(
                      child: CustomPaint(
                        painter: ProgressPainter(
                          progress: progress,
                          color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.9),
                          trackColor: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.1),
                        ),
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
                            showTimerPickerSheet(context, context.read<TimerService>());
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
