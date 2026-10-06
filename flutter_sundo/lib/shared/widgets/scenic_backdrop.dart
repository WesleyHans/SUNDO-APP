import 'package:flutter/material.dart';
import './time_based_background.dart';
import '../../core/theme/time_theme.dart';

// Retained for the operations illustration and existing asset preloading.
const clayHeroAsset = 'assets/images/clay-city-hero.png';
const sundoLeafSprigAsset = 'assets/images/sundo-leaf-sprig.png';

class ScenicBackdrop extends StatelessWidget {
  final Widget child;
  final Animation<double>? sceneryOpacity;
  const ScenicBackdrop({super.key, required this.child, this.sceneryOpacity});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        if (sceneryOpacity != null)
          Positioned.fill(
              child: ColoredBox(color: SundoTimeScope.of(context).background)),
        Positioned.fill(
            child: sceneryOpacity == null
                ? const SundoTimeBasedBackground()
                : FadeTransition(
                    key: const ValueKey('sundo-navigation-scenery-fade'),
                    opacity: sceneryOpacity!,
                    child: const SundoTimeBasedBackground())),
        child,
      ]);
}

/// The reference corner arrangement enters from the screen edges.
/// Paint below content so avatars, cards and controls remain clearly readable.
class SundoResidentLeaves extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const SundoResidentLeaves(
      {super.key, required this.child, this.enabled = true});
  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_ResidentLeafScope>() !=
        null) {
      return child;
    }
    return _ResidentLeafScope(
        child: Stack(fit: StackFit.expand, children: [
      Positioned(
          right: -22,
          top: -10,
          child:
              Visibility(visible: enabled, child: const LeafSprig(size: 110))),
      Positioned(
          left: -35,
          bottom: 25,
          child: Visibility(
              visible: enabled,
              child: const LeafSprig(size: 95, flipped: true))),
      child,
    ]));
  }
}

class _ResidentLeafScope extends InheritedWidget {
  const _ResidentLeafScope({required super.child});
  @override
  bool updateShouldNotify(_ResidentLeafScope oldWidget) => false;
}

/// Decorative leaves stay inside their own header surface, below system
/// insets. Painting behind titles/buttons leaves their hit targets unchanged.
class SundoHeaderLeaves extends StatelessWidget {
  const SundoHeaderLeaves({super.key});
  @override
  Widget build(BuildContext context) => const SafeArea(
        bottom: false,
        child: Align(
            alignment: Alignment.topRight,
            child: Padding(
                padding: EdgeInsets.only(top: 2, right: 6),
                child: Opacity(opacity: .24, child: LeafSprig(size: 48)))),
      );
}

/// Existing auth decorations remain independent of form scrolling.
class SundoLeafFrame extends StatelessWidget {
  final Widget child;
  final double size;
  const SundoLeafFrame({super.key, required this.child, this.size = 110});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Positioned(top: -10, right: -22, child: LeafSprig(size: size)),
        Positioned(
            left: -35,
            bottom: MediaQuery.paddingOf(context)
                .bottom
                .clamp(25.0, double.infinity),
            child: const LeafSprig(size: 95, flipped: true)),
        child,
      ]);
}

/// A detailed natural leaf asset preserves the existing decorative footprint.
class LeafSprig extends StatelessWidget {
  final double size;
  final bool flipped;
  const LeafSprig({super.key, this.size = 100, this.flipped = false});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Transform.flip(
          flipX: flipped,
          child: Image.asset(
            sundoLeafSprigAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: 512,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
}
