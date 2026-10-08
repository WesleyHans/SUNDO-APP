import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/clay_theme.dart';
import '../../../core/theme/time_theme.dart';
import '../../../models/map_tracking.dart';
import '../../../services/backend_service.dart';
import '../../../shared/widgets/sundo_graphics.dart';
import '../../live_map/widgets/map_tracking_widgets.dart';
import 'sundo_card_scenery.dart';

/// A single, slow clock shared by decorative Home painters. Content does not
/// rebuild on each tick, and the clock stops outside Home or in the background.
class SundoDashboardMotion extends StatefulWidget {
  final bool isActive;
  final Widget child;
  const SundoDashboardMotion(
      {super.key, required this.isActive, required this.child});

  @override
  State<SundoDashboardMotion> createState() => _SundoDashboardMotionState();
}

class _SundoDashboardMotionState extends State<SundoDashboardMotion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 18));
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SundoDashboardMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final enabled = widget.isActive &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (enabled && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!enabled && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SundoDashboardMotionScope(animation: _clock, child: widget.child);
}

class SundoDashboardMotionScope extends InheritedWidget {
  final Animation<double> animation;
  const SundoDashboardMotionScope(
      {super.key, required this.animation, required super.child});

  static Animation<double> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SundoDashboardMotionScope>()
          ?.animation ??
      const AlwaysStoppedAnimation(0);

  @override
  bool updateShouldNotify(SundoDashboardMotionScope oldWidget) =>
      oldWidget.animation != animation;
}

/// Small one-shot entrances preserve the scroll position and never replay for
/// weather or fleet updates. Reduced-motion users see the final layout directly.
class SundoDashboardEntrance extends StatefulWidget {
  final Widget child;
  final int order;
  final bool isActive;
  const SundoDashboardEntrance(
      {super.key, required this.child, this.order = 0, this.isActive = true});

  @override
  State<SundoDashboardEntrance> createState() => _SundoDashboardEntranceState();
}

class _SundoDashboardEntranceState extends State<SundoDashboardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + widget.order.clamp(0, 6) * 55));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !widget.isActive) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SundoDashboardEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = 600 + widget.order.clamp(0, 6) * 55;
    final animation = _controller.drive(CurveTween(
        curve: Interval((duration - 600) / duration, 1,
            curve: Curves.easeOutCubic)));
    return AnimatedBuilder(
        animation: animation,
        child: widget.child,
        builder: (context, child) => Opacity(
            opacity: animation.value,
            child: Transform.translate(
                offset: Offset(0, 9 * (1 - animation.value)), child: child)));
  }
}

enum SundoDashboardDecoration { none, info, weather, route }

/// Cream/green clay surfaces use the existing SUNDO palette, with decorations
/// clipped inside the card and painted behind its accessible real widgets.
class SundoDashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final SundoDashboardDecoration decoration;
  final SundoCardScene? scenery;
  const SundoDashboardCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.radius = 26,
      this.decoration = SundoDashboardDecoration.none,
      this.scenery});

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: mood.isNight
                    ? const [Color(0xFF233E30), Color(0xFF193127)]
                    : const [Color(0xFFFEFFFC), Color(0xFFEDFBEF)]),
            border: Border.all(
                color: mood.isNight
                    ? const Color(0xFF3B5B46)
                    : const Color(0xFFF8FFFA)),
            boxShadow: [
              BoxShadow(
                  color: mood.isNight
                      ? const Color(0x38000000)
                      : const Color(0x20277148),
                  offset: const Offset(0, 9),
                  blurRadius: 19,
                  spreadRadius: -4),
              if (!mood.isNight)
                const BoxShadow(
                    color: Color(0xBFFFFFFF),
                    offset: Offset(-2, -3),
                    blurRadius: 7)
            ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(children: [
              if (scenery != null) ...[
                Positioned.fill(
                    child: IgnorePointer(
                        child: ExcludeSemantics(
                            child: RepaintBoundary(
                                child: SundoCardScenery(scene: scenery!))))),
                Positioned.fill(
                    child: IgnorePointer(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0, .28, .85, 1],
                                    colors: mood.isNight
                                        ? const [
                                            Color(0xD91B3327),
                                            Color(0xDE1B3327),
                                            Color(0xD91B3327),
                                            Color(0x541B3327)
                                          ]
                                        : const [
                                            Color(0xC7FEFFFC),
                                            Color(0xCCFEFFFC),
                                            Color(0xC2FEFFFC),
                                            Color(0x54FEFFFC)
                                          ]))))),
              ],
              if (scenery == null &&
                  decoration != SundoDashboardDecoration.none)
                Positioned.fill(
                    child: IgnorePointer(
                        child: ExcludeSemantics(
                            child: RepaintBoundary(
                                child: CustomPaint(
                                    painter: _EcoDecorationPainter(
                                        animation: SundoDashboardMotionScope.of(
                                            context),
                                        kind: decoration,
                                        night: mood.isNight)))))),
              Padding(padding: padding, child: child)
            ])));
  }
}

class SundoGreetingHeader extends StatelessWidget {
  final String firstName;
  final String initials;
  final int unread;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  const SundoGreetingHeader(
      {super.key,
      required this.firstName,
      required this.initials,
      required this.unread,
      required this.onNotifications,
      required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final greeting = Text('${mood.greeting},',
        style: GoogleFonts.outfit(
            color: mood.textColor,
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.w700));
    final name = Row(children: [
      Flexible(
          child: Text('$firstName!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: mood.textColor))),
      const SizedBox(width: 6),
      Icon(mood.isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
          size: 29, color: const Color(0xFFF2BA27))
    ]);
    final controls = Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 48,
          height: 48,
          decoration: _roundDecoration(mood),
          child: Semantics(
              button: true,
              label: 'Notifications, $unread unread',
              onTap: onNotifications,
              excludeSemantics: true,
              child: Stack(clipBehavior: Clip.none, children: [
                IconButton(
                    onPressed: onNotifications,
                    tooltip: 'Notifications',
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.notifications_rounded,
                        size: 25, color: mood.textColor)),
                if (unread > 0)
                  Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF52CF62),
                              border:
                                  Border.all(color: mood.surface, width: 2))))
              ]))),
      const SizedBox(width: 11),
      _PressSurface(
          onTap: onProfile,
          label: 'Open profile',
          radius: 28,
          child: Container(
              width: 51,
              height: 51,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF39CC59), Color(0xFF007B36)]),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x230A6E38),
                        blurRadius: 12,
                        offset: Offset(0, 5))
                  ]),
              child: Text(initials,
                  style: GoogleFonts.outfit(
                      fontSize: 19,
                      color: Colors.white,
                      fontWeight: FontWeight.w700))))
    ]);
    return Padding(
        padding: const EdgeInsets.fromLTRB(18, 21, 18, 21),
        child: LayoutBuilder(builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(18) / 18;
          if (constraints.maxWidth / scale < 230) {
            return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: greeting),
                    const SizedBox(width: 10),
                    controls
                  ]),
                  const SizedBox(height: 6),
                  name
                ]);
          }
          return Row(children: [
            Expanded(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [greeting, const SizedBox(height: 4), name])),
            const SizedBox(width: 10),
            controls
          ]);
        }));
  }
}

class SundoInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? footer;
  final String? timeLabel;
  final String? additionalDetails;
  final SundoCardScene? scenery;
  const SundoInfoCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap,
      this.footer,
      this.timeLabel,
      this.additionalDetails,
      this.scenery});

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final secondaryColor = scenery != null && !mood.isNight
        ? const Color(0xFF345244)
        : mood.mutedTextColor;
    return _PressSurface(
        onTap: onTap,
        label: [title, subtitle, timeLabel, additionalDetails, footer]
            .whereType<String>()
            .join(', '),
        radius: 25,
        child: SundoDashboardCard(
            radius: 25,
            padding: const EdgeInsets.all(14),
            decoration: SundoDashboardDecoration.info,
            scenery: scenery,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        width: 51,
                        height: 51,
                        decoration: _roundDecoration(mood, green: true),
                        child: Icon(icon, size: 30, color: mood.accent)),
                    const Spacer(),
                    Container(
                        width: 31,
                        height: 31,
                        decoration: _roundDecoration(mood),
                        child: Icon(Icons.chevron_right_rounded,
                            size: 25, color: mood.textColor))
                  ]),
                  const SizedBox(height: 13),
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          height: 1.14,
                          color: mood.textColor,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: secondaryColor)),
                  if (timeLabel != null) ...[
                    const SizedBox(height: 9),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                            color: scenery == null
                                ? mood.accent.withValues(alpha: .10)
                                : mood.isNight
                                    ? const Color(0xEB294536)
                                    : const Color(0xEBEFFFEF),
                            borderRadius: BorderRadius.circular(13)),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.schedule_rounded,
                                  color: mood.accent, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(
                                      // Keep each time and its AM/PM together
                                      // when a narrow card needs two lines.
                                      timeLabel!.replaceAll(
                                          RegExp(r'\s+(?=[AP]M\b)'), '\u00A0'),
                                      style: TextStyle(
                                          color: mood.accent,
                                          fontSize: 11,
                                          height: 1.2,
                                          fontWeight: FontWeight.w800)))
                            ]))
                  ],
                  if (additionalDetails != null) ...[
                    const SizedBox(height: 7),
                    Text(additionalDetails!,
                        style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: secondaryColor))
                  ],
                  if (footer != null) ...[
                    const SizedBox(height: 9),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                            color: scenery == null
                                ? mood.accent.withValues(alpha: .10)
                                : mood.isNight
                                    ? const Color(0xEB294536)
                                    : const Color(0xEBEFFFEF),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(footer!,
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.3,
                                color: mood.accent,
                                fontWeight: FontWeight.w600)))
                  ]
                ])));
  }
}

class SundoLiveTruckCard extends StatelessWidget {
  final MapTruckSnapshot? truck;
  final VoidCallback onViewMap;
  const SundoLiveTruckCard({super.key, this.truck, required this.onViewMap});

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    final snapshot = truck;
    final fresh = snapshot?.freshAt(mood.now) ?? false;
    final available = snapshot != null &&
        fresh &&
        (snapshot.active || snapshot.stage == MapTrackingStage.completed);
    final status = snapshot == null
        ? 'Awaiting fleet data'
        : available
            ? mapStageLabel(snapshot.stage).toUpperCase()
            : 'OFFLINE';
    final distance = snapshot?.distanceKm;
    final eta = snapshot?.etaMinutes;
    final detail = snapshot == null
        ? (BackendService.live
            ? 'No position has been received.'
            : 'Starting the sample route…')
        : !fresh
            ? 'Waiting for a current truck position.'
            : '${distance == null ? 'Distance unavailable' : '${distance.toStringAsFixed(1)} km away'} · ${eta == null ? 'ETA unavailable' : 'ETA: $eta minutes'}';
    final source = snapshot == null
        ? null
        : '${snapshot.simulated ? 'Simulated collection' : fresh ? 'Live city update' : 'Last known position'}${snapshot.route.name.isEmpty ? '' : ' · ${snapshot.route.name}'}';
    return SundoDashboardCard(
        padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
        decoration: SundoDashboardDecoration.route,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 9,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Truck is $status',
                    style: GoogleFonts.outfit(
                        fontSize: 22,
                        height: 1.1,
                        color: mood.textColor,
                        fontWeight: FontWeight.w800)),
                if (available)
                  Semantics(
                      label: snapshot.simulated
                          ? 'Live demo updates'
                          : 'Live city updates',
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                              color: mood.accent.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(15)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox.square(
                                dimension: 7,
                                child: CustomPaint(
                                    painter: _LiveDotPainter(
                                        animation: SundoDashboardMotionScope.of(
                                            context),
                                        color: mood.accent))),
                            const SizedBox(width: 5),
                            Text('LIVE',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: mood.accent,
                                    fontWeight: FontWeight.w800))
                          ])))
              ]),
          const SizedBox(height: 8),
          Text(detail,
              style: TextStyle(
                  fontSize: 14, height: 1.3, color: mood.mutedTextColor)),
          if (source != null) ...[
            const SizedBox(height: 4),
            Text(source,
                style: TextStyle(
                    fontSize: 10.5, height: 1.35, color: mood.mutedTextColor))
          ],
          const SizedBox(height: 1),
          const Align(
              alignment: Alignment.centerRight,
              child: SundoTruckGraphic(width: 124, height: 62)),
          Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: mood.surface.withValues(alpha: .93),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: mood.surface)),
              child: SundoProgressTracker(
                  stage: snapshot?.stage ?? MapTrackingStage.notStarted,
                  available: available)),
          const SizedBox(height: 11),
          _DashboardPrimaryButton(onPressed: onViewMap)
        ]));
  }
}

/// Home's five stages keep whole words at small phone widths. Large system
/// text uses a wrapping list of complete stage labels instead of shrinking it.
class SundoProgressTracker extends StatelessWidget {
  final MapTrackingStage stage;
  final bool available;
  const SundoProgressTracker(
      {super.key, required this.stage, this.available = true});

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Semantics(
        label: available
            ? 'Collection status: ${mapStageLabel(stage)}'
            : 'Collection status unavailable',
        excludeSemantics: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
          if (constraints.maxWidth / scale < 235) {
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Wrap(spacing: 13, runSpacing: 9, children: [
                  for (final value in MapTrackingStage.values)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle,
                          size: 9,
                          color: available && value.index <= stage.index
                              ? mood.accent
                              : mood.mutedTextColor.withValues(alpha: .35)),
                      const SizedBox(width: 5),
                      Text(mapStageLabel(value),
                          style: TextStyle(
                              fontSize: 10,
                              color: available && value == stage
                                  ? mood.accent
                                  : mood.mutedTextColor,
                              fontWeight: available && value == stage
                                  ? FontWeight.w800
                                  : FontWeight.w500))
                    ])
                ]));
          }
          final fontSize = constraints.maxWidth < 280 ? 8.5 : 9.5;
          // Longer labels receive more room, while each node stays centered
          // above its own label at both regular and compact phone widths.
          const columnWeights = [12, 10, 14, 9, 12];
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              for (var index = 0; index < 5; index++)
                Expanded(
                    flex: columnWeights[index],
                    child: SizedBox(
                        height: 14,
                        child: Stack(alignment: Alignment.center, children: [
                          Positioned.fill(
                              child: Row(children: [
                            Expanded(
                                child: Container(
                                    height: 3,
                                    color: index == 0
                                        ? Colors.transparent
                                        : available && index <= stage.index
                                            ? mood.accent
                                            : mood.mutedTextColor
                                                .withValues(alpha: .25))),
                            Expanded(
                                child: Container(
                                    height: 3,
                                    color: index == 4
                                        ? Colors.transparent
                                        : available && index < stage.index
                                            ? mood.accent
                                            : mood.mutedTextColor
                                                .withValues(alpha: .25)))
                          ])),
                          Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: available && index <= stage.index
                                      ? mood.accent
                                      : mood.mutedTextColor
                                          .withValues(alpha: .35),
                                  border: Border.all(
                                      color: mood.surface, width: 2)))
                        ])))
            ]),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final value in MapTrackingStage.values)
                Expanded(
                    flex: columnWeights[value.index],
                    child: Text(
                        switch (value) {
                          MapTrackingStage.notStarted
                              when constraints.maxWidth < 280 =>
                            'Not\nStarted',
                          MapTrackingStage.onRoute
                              when constraints.maxWidth < 280 =>
                            'On\nRoute',
                          _ => mapStageLabel(value)
                        },
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: fontSize,
                            height: 1.25,
                            color: available && value == stage
                                ? mood.accent
                                : mood.mutedTextColor,
                            fontWeight: available && value == stage
                                ? FontWeight.w800
                                : FontWeight.w500)))
            ])
          ]);
        }));
  }
}

class _DashboardPrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DashboardPrimaryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => _PressSurface(
      onTap: onPressed,
      label: 'View Live Truck',
      radius: 24,
      child: Container(
          constraints: const BoxConstraints(minHeight: 53),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: ClayTheme.buttonPrimary(radius: 24),
          child: Row(children: [
            const Icon(Icons.location_on_rounded,
                size: 26, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
                child: Text('View Live Truck',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.15,
                        fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                size: 23, color: Colors.white)
          ])));
}

class _PressSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String label;
  final double radius;
  const _PressSurface(
      {required this.child,
      required this.onTap,
      required this.label,
      required this.radius});

  @override
  State<_PressSurface> createState() => _PressSurfaceState();
}

class _PressSurfaceState extends State<_PressSurface> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: AnimatedScale(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          scale: _pressed ? .985 : 1,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: widget.onTap,
                  onHighlightChanged: (value) =>
                      setState(() => _pressed = value),
                  borderRadius: BorderRadius.circular(widget.radius),
                  splashColor: const Color(0x170B8F3E),
                  highlightColor: const Color(0x0B0B8F3E),
                  child: widget.child))));
}

BoxDecoration _roundDecoration(SundoTimeMood mood, {bool green = false}) =>
    BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: mood.isNight
                ? const [Color(0xFF35513D), Color(0xFF203A2C)]
                : green
                    ? const [Color(0xFFEDFFE9), Color(0xFFD4F7D5)]
                    : const [Color(0xFFFEFFFC), Color(0xFFE3FAE6)]),
        border: Border.all(
            color: mood.isNight
                ? const Color(0xFF4A6751)
                : Colors.white.withValues(alpha: .9)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x141B733C), blurRadius: 9, offset: Offset(0, 4))
        ]);

class _LiveDotPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  _LiveDotPainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(animation.value * math.pi * 6);
    canvas.drawCircle(
        size.center(Offset.zero),
        size.shortestSide * (.43 + wave * .045),
        Paint()..color = color.withValues(alpha: .88 + wave * .1));
  }

  @override
  bool shouldRepaint(_LiveDotPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.animation != animation;
}

class _EcoDecorationPainter extends CustomPainter {
  final Animation<double> animation;
  final SundoDashboardDecoration kind;
  final bool night;
  _EcoDecorationPainter(
      {required this.animation, required this.kind, required this.night})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(animation.value * math.pi * 2);
    final opacity = night ? .10 : .22;
    final green = const Color(0xFF54B850).withValues(alpha: opacity);
    final soft = const Color(0xFFACED93).withValues(alpha: opacity * .8);
    if (kind == SundoDashboardDecoration.weather) {
      _cloud(canvas, Offset(size.width * .72 + wave * 6, size.height * .40), 42,
          night ? const Color(0x173DB987) : const Color(0xBFFFFFFF));
      _cloud(canvas, Offset(size.width * .92 - wave * 4, size.height * .28), 52,
          night ? const Color(0x153DB987) : const Color(0xDDFFFFFF));
      _leaf(canvas, Offset(size.width * .74, size.height * 1.04),
          const Size(29, 65), -.60 + wave * .025, green);
      _leaf(canvas, Offset(size.width * .88, size.height * 1.05),
          const Size(19, 45), -.32 - wave * .025, green);
    } else if (kind == SundoDashboardDecoration.info) {
      _leaf(canvas, Offset(size.width * 1.04, size.height * .91),
          const Size(33, 85), .30 + wave * .035, soft);
      _leaf(canvas, Offset(size.width * .93, size.height * .66),
          const Size(27, 61), -.54 - wave * .025, green);
      _leaf(canvas, Offset(size.width * .93, size.height * 1.13),
          const Size(39, 84), -.34 + wave * .025, soft);
    } else if (kind == SundoDashboardDecoration.route) {
      final horizon = size.height * .44;
      final building = Paint()
        ..color = const Color(0xFF66C6A9).withValues(alpha: opacity * .7);
      for (var i = 0; i < 5; i++) {
        final left = size.width * (.57 + i * .066);
        final height = 20.0 + (i % 3) * 9;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(left, horizon - height, 18, height + 17),
                const Radius.circular(2)),
            building);
        for (var y = 0; y < 2; y++) {
          canvas.drawRect(
              Rect.fromLTWH(left + 4, horizon - height + 6 + y * 9, 3, 4),
              Paint()..color = Colors.white.withValues(alpha: .5));
        }
      }
      final hills = Path()
        ..moveTo(0, horizon + 38)
        ..quadraticBezierTo(
            size.width * .22, horizon - 20, size.width * .4, horizon + 29)
        ..quadraticBezierTo(
            size.width * .74, horizon - 17, size.width, horizon + 12)
        ..lineTo(size.width, horizon + 66)
        ..lineTo(0, horizon + 66)
        ..close();
      canvas.drawPath(hills, Paint()..color = soft);
      final road = Path()
        ..moveTo(size.width * .31, horizon + 62)
        ..cubicTo(size.width * .65, horizon + 58, size.width * .96,
            horizon + 54, size.width * .84, horizon + 20);
      canvas.drawPath(
          road,
          Paint()
            ..color = const Color(0xFF92A99A).withValues(alpha: opacity * .6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 18);
      canvas.drawPath(
          road,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity * 2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      _cloud(canvas, Offset(size.width * .74 + wave * 5, horizon - 67), 45,
          Colors.white.withValues(alpha: night ? .07 : .66));
      _leaf(canvas, Offset(size.width * .99, horizon + 24), const Size(24, 70),
          .32 + wave * .025, green);
      _leaf(canvas, Offset(size.width * .11, horizon + 73), const Size(23, 63),
          -.58 - wave * .025, green);
    }
    // A low-contrast rim highlight drifts across decoration only, below text.
    final highlight =
        Offset(size.width * (.64 + wave * .06), size.height * .93);
    canvas.drawOval(
        Rect.fromCenter(center: highlight, width: size.width * .42, height: 18),
        Paint()
          ..color = Colors.white.withValues(alpha: night ? .015 : .10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
  }

  void _cloud(Canvas canvas, Offset origin, double width, Color color) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(origin.dx, origin.dy, width, width * .30),
            Radius.circular(width * .15)),
        paint);
    canvas.drawCircle(origin + Offset(width * .32, 0), width * .19, paint);
    canvas.drawCircle(
        origin + Offset(width * .57, -width * .06), width * .24, paint);
    canvas.drawCircle(origin + Offset(width * .78, 0), width * .17, paint);
  }

  void _leaf(
      Canvas canvas, Offset bottom, Size size, double angle, Color color) {
    canvas.save();
    canvas.translate(bottom.dx, bottom.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(-size.width * .8, -size.height * .22, -size.width * .63,
          -size.height * .65, 0, -size.height)
      ..cubicTo(size.width * .63, -size.height * .67, size.width * .78,
          -size.height * .23, 0, 0);
    canvas.drawPath(leaf, Paint()..color = color);
    canvas.drawPath(
        Path()
          ..moveTo(0, -3)
          ..quadraticBezierTo(
              -size.width * .08, -size.height * .49, 0, -size.height * .92),
        Paint()
          ..color = const Color(0xFF338B4E).withValues(alpha: color.a * .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EcoDecorationPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.night != night ||
      oldDelegate.animation != animation;
}
