import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../timer_service.dart';

class CycleIndicator extends StatelessWidget {
  const CycleIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<TimerService, ({int count, TimerMode mode, int contentColor})>(
      selector: (_, service) => (
        count: service.cycleCount,
        mode: service.currentMode,
        contentColor: service.contentColor
      ),
      builder: (context, data, _) {
        final cycleCount = data.count;
        final mode = data.mode;
        final color = Color(data.contentColor);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            return _buildDot(index, cycleCount, mode, color);
          }),
        );
      },
    );
  }

  Widget _buildDot(int index, int cycleCount, TimerMode mode, Color color) {
    bool isCompleted = false;
    bool isActive = false;

    if (mode == TimerMode.longBreak) {
      isCompleted = true;
    } else {
      final relativeCount = cycleCount % 4;
      if (relativeCount > index) {
        isCompleted = true;
      } else if (relativeCount == index && mode == TimerMode.focus) {
        isActive = true;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? color.withValues(alpha: 0.6)
            : isActive
                ? color
                : color.withValues(alpha: 0.15),
        border: isActive || isCompleted
            ? null
            : Border.all(color: color.withValues(alpha: 0.3), width: 1), 
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }
}
