import 'package:flutter/material.dart';

/// Changes the displayed selection only when its foreground has faded out.
/// Keep the builder's widget type and keys stable to retain tab/form state.
class SundoFadeThrough<T> extends StatefulWidget {
  final T value;
  final Widget Function(BuildContext context, T value) builder;

  const SundoFadeThrough({
    super.key,
    required this.value,
    required this.builder,
  });

  static const fadeOutDuration = Duration(milliseconds: 140);
  static const fadeInDuration = Duration(milliseconds: 260);

  @override
  State<SundoFadeThrough<T>> createState() => _SundoFadeThroughState<T>();
}

class _SundoFadeThroughState<T> extends State<SundoFadeThrough<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _opacity;
  late T _displayedValue;
  late T _requestedValue;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _displayedValue = widget.value;
    _requestedValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      value: 1,
      duration: SundoFadeThrough.fadeInDuration,
      reverseDuration: SundoFadeThrough.fadeOutDuration,
    )..addStatusListener(_onStatus);
    // Use the same curve in both directions so rapid selections can reverse
    // the current fade without changing its visible opacity abruptly.
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _showImmediately();
  }

  @override
  void didUpdateWidget(covariant SundoFadeThrough<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _requestedValue) return;
    _requestedValue = widget.value;
    if (_reduceMotion) {
      _showImmediately();
      return;
    }
    if (_displayedValue == _requestedValue && _controller.isCompleted) return;
    if (_controller.isDismissed) {
      _displayedValue = _requestedValue;
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _showImmediately() {
    _controller.stop();
    _displayedValue = widget.value;
    _requestedValue = widget.value;
    _controller.value = 1;
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || !mounted) return;
    setState(() => _displayedValue = _requestedValue);
    _controller.forward();
  }

  @override
  void dispose() {
    _opacity.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        // A stable Builder retains the foreground subtree while opacity
        // changes; the selection is rebuilt only on parent updates/handoffs.
        child: Builder(
            builder: (context) => widget.builder(context, _displayedValue)),
        builder: (context, child) => IgnorePointer(
          ignoring: !_controller.isCompleted,
          child: FadeTransition(opacity: _opacity, child: child),
        ),
      );
}
