import 'package:flutter/material.dart';
import 'scenic_backdrop.dart';

/// Screen controls belong to the open content area, without a painted title bar.
class SundoResidentContent extends StatelessWidget {
  final List<Widget> actions;
  final Widget? filters;
  final Widget body;
  final double topClearance;
  const SundoResidentContent(
      {super.key,
      this.actions = const [],
      this.filters,
      required this.body,
      this.topClearance = 120});

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          child: SundoResidentLeaves(
              child: Column(children: [
        AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: topClearance,
            width: double.infinity,
            child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 124, 0),
                    child: Row(
                        mainAxisSize: MainAxisSize.min, children: actions)))),
        if (filters != null) filters!,
        Expanded(child: body),
      ]))));
}
