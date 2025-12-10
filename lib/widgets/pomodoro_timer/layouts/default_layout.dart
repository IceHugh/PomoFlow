
import 'dart:math';
import 'package:flutter/cupertino.dart';
import '../top_bar.dart';
import '../timer_display.dart';
import '../timer_controls.dart';
import '../cycle_indicator.dart';

class DefaultLayout extends StatelessWidget {
  const DefaultLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(),
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
                        TimerDisplay(circleSize: circleSize),
                        const SizedBox(height: 20),
                        const CycleIndicator(),
                        const SizedBox(height: 20),
                        const TimerControls(),
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
    );
  }
}
