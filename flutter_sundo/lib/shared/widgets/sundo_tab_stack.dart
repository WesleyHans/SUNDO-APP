import 'package:flutter/material.dart';

/// Keeps tab elements alive while fading their visibility. Each layer animates
/// from its current opacity so rapid tab changes do not restart at full opacity.
class SundoTabStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const SundoTabStack({super.key, required this.index, required this.children})
      : assert(index >= 0 && index < children.length);

  @override
  State<SundoTabStack> createState() => _SundoTabStackState();
}

class _SundoTabStackState extends State<SundoTabStack>
    with TickerProviderStateMixin {
  final _opacities = <AnimationController>[];
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  void _syncControllers() {
    while (_opacities.length > widget.children.length) {
      _opacities.removeLast().dispose();
    }
    while (_opacities.length < widget.children.length) {
      _opacities.add(AnimationController(
          vsync: this,
          value: _opacities.length == widget.index ? 1 : 0,
          duration: const Duration(milliseconds: 420)));
    }
  }

  void _select() {
    for (var i = 0; i < _opacities.length; i++) {
      final target = i == widget.index ? 1.0 : 0.0;
      if (_reduceMotion) {
        _opacities[i].value = target;
      } else {
        _opacities[i].animateTo(target, curve: Curves.easeInOutCubic);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced != _reduceMotion) {
      _reduceMotion = reduced;
      _select();
    }
  }

  @override
  void didUpdateWidget(covariant SundoTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
    if (oldWidget.index != widget.index ||
        oldWidget.children.length != widget.children.length) {
      _select();
    }
  }

  @override
  void dispose() {
    for (final animation in _opacities) {
      animation.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge(_opacities),
      builder: (context, _) {
        final order = [
          for (var i = 0; i < widget.children.length; i++)
            if (i != widget.index) i,
          widget.index
        ];
        return Stack(fit: StackFit.expand, children: [
          for (final i in order)
            Offstage(
                key: ValueKey(i),
                offstage: i != widget.index && _opacities[i].value == 0,
                child: TickerMode(
                    enabled: i == widget.index,
                    child: IgnorePointer(
                        ignoring: i != widget.index,
                        child: ExcludeFocus(
                            excluding: i != widget.index,
                            child: ExcludeSemantics(
                                excluding: i != widget.index,
                                child: FadeTransition(
                                    opacity: _opacities[i],
                                    child: widget.children[i])))))),
        ]);
      });
}
