
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../timer_service.dart';
import '../../settings_page.dart';
import '../glass_container.dart';
import '../../statistics_page.dart';
import 'package:window_manager/window_manager.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(50),
                        blur: context.select<TimerService, String>((s) => s.backgroundType) == 'image' ? 0 : 15,
                        opacity: 0.1,
                        color: Color(context.select<TimerService, int>((s) => s.contentColor)),
                        border: Border.all(color: Color(context.select<TimerService, int>((s) => s.contentColor)).withValues(alpha: 0.2), width: 0.5),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(CupertinoIcons.chart_bar_alt_fill, size: 20, color: Color(context.select<TimerService, int>((s) => s.contentColor))),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const StatisticsPage(),
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
                    const SizedBox(width: 12),
                    CupertinoButton(
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
