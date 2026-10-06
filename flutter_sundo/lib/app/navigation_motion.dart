import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/scenic_backdrop.dart';

const sundoPageTransitionDuration = Duration(milliseconds: 450);

Widget sundoPageFade(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  return AnimatedBuilder(
    animation: Listenable.merge([animation, secondaryAnimation]),
    child: FadeTransition(
      key: const ValueKey('sundo-page-fade'),
      opacity: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
      child: FadeTransition(
        key: const ValueKey('sundo-page-outgoing-fade'),
        opacity: secondaryAnimation.drive(Tween<double>(begin: 1, end: 0).chain(
            CurveTween(
                curve: const Interval(0, .4, curve: Curves.easeOutCubic)))),
        child: child,
      ),
    ),
    builder: (context, child) => IgnorePointer(
      ignoring: animation.status != AnimationStatus.completed ||
          secondaryAnimation.value > 0,
      child: child,
    ),
  );
}

CustomTransitionPage<void> sundoPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: sundoPageTransitionDuration,
      reverseTransitionDuration: sundoPageTransitionDuration,
      transitionsBuilder: sundoPageFade,
    );

PageRoute<T> sundoPageRoute<T>({required WidgetBuilder builder}) =>
    PageRouteBuilder<T>(
      pageBuilder: (context, _, __) => builder(context),
      transitionDuration: sundoPageTransitionDuration,
      reverseTransitionDuration: sundoPageTransitionDuration,
      transitionsBuilder: sundoPageFade,
    );

/// Scenery stays mounted across inner pages. When an opaque artwork page is
/// replaced, reveal the soft scene together with the arriving page content.
class SundoNavigationBackdrop extends StatefulWidget {
  const SundoNavigationBackdrop(
      {super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<SundoNavigationBackdrop> createState() =>
      _SundoNavigationBackdropState();
}

class _SundoNavigationBackdropState extends State<SundoNavigationBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: sundoPageTransitionDuration, value: 1);
  late final Animation<double> _opacity =
      _controller.drive(CurveTween(curve: Curves.easeInOutCubic));
  String? _path;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _rememberPath();
    widget.router.routerDelegate.addListener(_routeChanged);
  }

  String? get _currentPath =>
      widget.router.routerDelegate.currentConfiguration.isEmpty
          ? null
          : widget.router.state.uri.path;

  void _rememberPath() => _path = _currentPath;

  bool _fullScene(String? path) => path == '/' || path == '/welcome';

  void _routeChanged() {
    final next = _currentPath;
    if (next == null || next == _path) return;
    final revealScene = _fullScene(_path) && !_fullScene(next);
    _path = next;
    if (revealScene && !_reduceMotion) _controller.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(SundoNavigationBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.router != oldWidget.router) {
      oldWidget.router.routerDelegate.removeListener(_routeChanged);
      _rememberPath();
      widget.router.routerDelegate.addListener(_routeChanged);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_routeChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScenicBackdrop(sceneryOpacity: _opacity, child: widget.child);
}
