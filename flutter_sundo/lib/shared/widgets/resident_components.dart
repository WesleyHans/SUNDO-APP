import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/time_theme.dart';
import '../../core/theme/clay_theme.dart';

class SundoPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const SundoPrimaryButton(
      {super.key, required this.label, this.onPressed, this.icon});
  @override
  Widget build(BuildContext context) => Opacity(
      opacity: onPressed == null ? .55 : 1,
      child: Container(
          height: 52,
          decoration: ClayTheme.buttonPrimary(radius: 18),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onPressed,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label,
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        if (icon != null) ...[
                          const SizedBox(width: 12),
                          Icon(icon, color: Colors.white, size: 20)
                        ],
                      ])))));
}

class SundoSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const SundoSecondaryButton({super.key, required this.label, this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)));
}

class SundoSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const SundoSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.radius = 18});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Container(
        padding: padding,
        decoration: mood.isNight
            ? BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF20382B), Color(0xFF192D23)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: const Color(0xFF355641)),
                boxShadow: const [
                    BoxShadow(
                        color: Color(0x66000000),
                        offset: Offset(3, 6),
                        blurRadius: 14)
                  ])
            : ClayTheme.card(radius: radius),
        child: child);
  }
}

class SundoDynamicGreeting extends StatelessWidget {
  final String firstName;
  const SundoDynamicGreeting({super.key, required this.firstName});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${mood.greeting},',
          style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: mood.textColor)),
      Row(children: [
        Flexible(
            child: Text('$firstName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: mood.textColor))),
        const SizedBox(width: 8),
        Icon(mood.isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            size: 24,
            color: mood.isNight
                ? const Color(0xFFFFE4A4)
                : const Color(0xFFF4B521))
      ]),
    ]);
  }
}

class SundoQuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const SundoQuickActionCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: SundoSurface(
                radius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(children: [
                  Container(
                      width: 33,
                      height: 38,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 22)),
                  const SizedBox(width: 9),
                  Expanded(
                      child: Text(title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: mood.textColor))),
                ]))));
  }
}

class SundoBottomNavigation extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final int unread;
  const SundoBottomNavigation(
      {super.key,
      required this.index,
      required this.onChanged,
      this.unread = 0});
  static const labels = ['Home', 'Live Map', 'Schedule', 'Alerts', 'Profile'];
  static const icons = [
    Icons.home_rounded,
    Icons.map_outlined,
    Icons.calendar_month_rounded,
    Icons.notifications_outlined,
    Icons.person_outline
  ];
  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return Container(
        decoration: BoxDecoration(
            color: mood.surface,
            border: Border(
                top: BorderSide(
                    color: mood.isNight
                        ? const Color(0xFF33523D)
                        : const Color(0xFFE4EFE7))),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x16263F29),
                  blurRadius: 14,
                  offset: Offset(0, -3))
            ]),
        child: SafeArea(
            top: false,
            child: Row(
                children: List.generate(
                    labels.length,
                    (i) => Expanded(
                        child: Semantics(
                            selected: index == i,
                            button: true,
                            label: labels[i],
                            child: InkWell(
                                onTap: () => onChanged(i),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Icon(icons[i],
                                                    size: 24,
                                                    color: index == i
                                                        ? mood.accent
                                                        : mood.mutedTextColor),
                                                if (i == 3 && unread > 0)
                                                  Positioned(
                                                      top: -3,
                                                      right: -3,
                                                      child: Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration:
                                                              const BoxDecoration(
                                                                  color: Color(
                                                                      0xFFDC3B3B),
                                                                  shape: BoxShape
                                                                      .circle)))
                                              ]),
                                          const SizedBox(height: 4),
                                          Text(labels[i],
                                              style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: index == i
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: index == i
                                                      ? mood.accent
                                                      : mood.mutedTextColor))
                                        ])))))))));
  }
}
