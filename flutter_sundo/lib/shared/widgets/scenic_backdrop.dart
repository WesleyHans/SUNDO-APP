import 'package:flutter/material.dart';
import './time_based_background.dart';

// Retained for the operations illustration and existing asset preloading.
const clayHeroAsset = 'assets/images/clay-city-hero.png';
const sundoLeafSprigAsset = 'assets/images/sundo-leaf-sprig.png';

class ScenicBackdrop extends StatelessWidget {
  final Widget child;
  const ScenicBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const Positioned.fill(child: SundoTimeBasedBackground()),
        child,
      ]);
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
