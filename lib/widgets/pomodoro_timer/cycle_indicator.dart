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
    final relativeCount = cycleCount % 4;
    
    // 判断当前圆点的状态
    bool isCompleted = relativeCount > index;
    bool isCurrentCycle = relativeCount == index;
    
    // 判断当前模式
    bool isFocusing = isCurrentCycle && mode == TimerMode.focus;
    bool isShortBreak = isCurrentCycle && mode == TimerMode.shortBreak;
    bool isLongBreak = mode == TimerMode.longBreak;

    // 尺寸：活跃状态稍大
    double size = (isFocusing || isShortBreak) ? 10 : 8;
    
    // Long Break 时所有圆点都显示完成状态
    if (isLongBreak) {
      return _buildLongBreakDot(color, size);
    }
    
    // Focus 状态：实心圆 + 光晕
    if (isFocusing) {
      return _buildFocusDot(color, size);
    }
    
    // Short Break 状态：空心圆环（粗边框）
    if (isShortBreak) {
      return _buildShortBreakDot(color, size);
    }
    
    // 已完成：半透明实心圆
    if (isCompleted) {
      return _buildCompletedDot(color, size);
    }
    
    // 未开始：淡色空心圆
    return _buildPendingDot(color, size);
  }

  // Focus 状态：实心圆 + 浓重光晕
  Widget _buildFocusDot(Color color, double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6), // 增加光晕浓度
            blurRadius: 10,
            spreadRadius: 3,
          )
        ],
      ),
    );
  }

  // Short Break 状态：空心圆环 + 微弱底色
  Widget _buildShortBreakDot(Color color, double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1), // 增加微弱底色
        border: Border.all(
          color: color.withValues(alpha: 1.0), // 实心边框
          width: 2.0,
        ),
        // 移除阴影，保持清爽，避免在白色背景看起来脏
      ),
    );
  }

  // Long Break 状态：明显的双圆环/填充效果
  Widget _buildLongBreakDot(Color color, double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3), // 明显的填充
        border: Border.all(
          color: color.withValues(alpha: 1.0), // 实心边框
          width: 2.0,
        ),
      ),
    );
  }

  // 已完成：高透明度实心
  Widget _buildCompletedDot(Color color, double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.7), // 提高完成状态的可见度 (原0.6)
      ),
    );
  }

  // 未开始：加粗、加深边框 + 微弱底色
  Widget _buildPendingDot(Color color, double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.05), // 极淡的底色占位
        border: Border.all(
          color: color.withValues(alpha: 0.4), // 提高边框可见度 (原0.25)
          width: 1.5, // 加粗 (原1.0)
        ),
      ),
    );
  }
}
