import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/time_theme.dart';
import 'scenic_backdrop.dart';

class ResidentHeaderController extends ChangeNotifier {
  final _actions = <int, List<Widget>>{};
  List<Widget> actionsFor(int index) => _actions[index] ?? const [];
  void publish(int index, List<Widget> actions) {
    _actions[index] = actions;
    notifyListeners();
  }
}

class ResidentHeaderScope extends InheritedWidget {
  final ResidentHeaderController controller;
  final int index;
  final bool active;
  const ResidentHeaderScope(
      {super.key,
      required this.controller,
      required this.index,
      required this.active,
      required super.child});
  @override
  bool updateShouldNotify(ResidentHeaderScope oldWidget) =>
      active != oldWidget.active;
}

/// Shared resident tabs publish their existing actions, retaining their own
/// callbacks/state. Filters remain inside the tab so header height never jumps.
Widget sundoResidentScreen(
  BuildContext context, {
  required AppBar appBar,
  required Widget body,
  Color? backgroundColor,
}) {
  final scope =
      context.dependOnInheritedWidgetOfExactType<ResidentHeaderScope>();
  if (scope != null && scope.active) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final current =
          context.getInheritedWidgetOfExactType<ResidentHeaderScope>();
      if (current?.active == true) {
        current!.controller.publish(current.index, appBar.actions ?? const []);
      }
    });
  }
  return Scaffold(
      backgroundColor: backgroundColor,
      appBar: scope == null ? appBar : null,
      body: scope == null || appBar.bottom == null
          ? body
          : Column(children: [appBar.bottom!, Expanded(child: body)]));
}

class SundoResidentHeader extends StatelessWidget {
  final ResidentHeaderController controller;
  final int index;
  const SundoResidentHeader(
      {super.key, required this.controller, required this.index});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
        height: 56,
        child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) =>
                Stack(alignment: Alignment.center, children: [
                  const Positioned(
                      right: 0,
                      top: 0,
                      width: 56,
                      height: 56,
                      child: SundoHeaderLeaves()),
                  Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: controller.actionsFor(index).length > 1
                              ? 100
                              : 64),
                      child: AnimatedSwitcher(
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 250),
                          child: Text(
                              [
                                'SUNDO',
                                'Live Map',
                                'Schedule',
                                'Alerts',
                                'Profile'
                              ][index],
                              key: ValueKey(index),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: mood.textColor)))),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          layoutBuilder: (current, previous) =>
                              Stack(alignment: Alignment.centerLeft, children: [
                                for (final child in previous)
                                  ExcludeSemantics(
                                      child: ExcludeFocus(
                                          child: IgnorePointer(child: child))),
                                if (current != null) current,
                              ]),
                          child: SizedBox(
                              key: ValueKey(index),
                              width: controller.actionsFor(index).isEmpty
                                  ? 56
                                  : null,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: controller.actionsFor(index))))),
                ])));
  }
}
