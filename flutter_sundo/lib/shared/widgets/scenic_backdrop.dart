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
        const Positioned(right: -22, top: -10, child: LeafSprig(size: 110)),
        const Positioned(
            left: -35, bottom: 25, child: LeafSprig(size: 95, flipped: true)),
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
