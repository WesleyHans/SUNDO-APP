import 'package:flutter/material.dart';
import 'scenic_backdrop.dart';

/// Transparent resident frame. Its body owns the complete scrolling content.
class SundoResidentContent extends StatelessWidget {
  final Widget body;
  const SundoResidentContent({super.key, required this.body});

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: SundoResidentLeaves(child: body)));
}

/// Compact actions and filters scroll together with the screen's cards/form.
/// The right inset keeps action hit targets away from the decorative leaves.
class SundoResidentInlineControls extends StatelessWidget {
  final List<Widget> actions;
  final Widget? filters;
  const SundoResidentInlineControls(
      {super.key, this.actions = const [], this.filters});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (actions.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(right: 106, bottom: 12),
              child: Wrap(children: actions)),
        if (filters != null) filters!,
      ]);
}
