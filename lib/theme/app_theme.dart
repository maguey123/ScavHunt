import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  ScavHunt Design System
//  Dark minimal — mirrors maguires.site/scav
// ─────────────────────────────────────────────

class ScavColors {
  static const bg           = Color(0xFF0A0A0F);
  static const surface      = Color(0xFF13131A);
  static const surfaceHi    = Color(0xFF1A1A26);
  static const border       = Color(0xFF1E1E2E);
  static const borderHi     = Color(0xFF2A2A3E);
  static const accent       = Color(0xFFFF6B35);
  static const accentLo     = Color(0x20FF6B35);
  static const accentMid    = Color(0x40FF6B35);
  static const textPrimary  = Color(0xFFF0F0F5);
  static const textSecondary= Color(0xFF8888A0);
  static const textMuted    = Color(0xFF55556A);
  static const green        = Color(0xFF2DD4BF);
  static const greenLo      = Color(0x202DD4BF);
  static const red          = Color(0xFFFF4757);
  static const redLo        = Color(0x20FF4757);
  static const amber        = Color(0xFFFFBB33);
  static const amberLo      = Color(0x20FFBB33);
  static const purple       = Color(0xFF9B59B6);
  static const purpleLo     = Color(0x209B59B6);
}

class ScavTheme {
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ScavColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: ScavColors.accent,
      secondary: ScavColors.accent,
      surface: ScavColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ScavColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ScavColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: ScavColors.textSecondary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: ScavColors.bg,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ScavColors.surface,
      labelStyle: const TextStyle(color: ScavColors.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: ScavColors.textMuted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ScavColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ScavColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ScavColors.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ScavColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ScavColors.textPrimary,
        side: const BorderSide(color: ScavColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: ScavColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ScavColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: ScavColors.border, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ScavColors.surfaceHi,
      contentTextStyle: const TextStyle(color: ScavColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ScavColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(ScavColors.surface),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: ScavColors.accent,
      inactiveTrackColor: ScavColors.border,
      thumbColor: ScavColors.accent,
      overlayColor: ScavColors.accentLo,
      trackHeight: 3,
    ),
  );
}

// ─────────────────────────────────────────────
//  Shared Widgets
// ─────────────────────────────────────────────

class ScavLogo extends StatelessWidget {
  final double size;
  const ScavLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: ScavColors.accent,
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
    child: Center(
      child: Text('S', style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.52,
        fontWeight: FontWeight.w900,
        height: 1,
      )),
    ),
  );
}

class ScavSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets? padding;
  const ScavSectionLabel(this.text, {super.key, this.padding});

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.fromLTRB(0, 20, 0, 8),
    child: Text(text.toUpperCase(), style: const TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: ScavColors.textMuted, letterSpacing: 1.2,
    )),
  );
}

class ScavPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const ScavPrimaryButton({
    super.key, required this.label,
    this.onPressed, this.isLoading = false, this.icon, this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color ?? ScavColors.accent),
      child: isLoading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
              const SizedBox(width: 6),
              const Text('→', style: TextStyle(fontSize: 16)),
            ]),
    ),
  );
}

class ScavSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const ScavSecondaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label),
      ]),
    ),
  );
}

class ScavStatusBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData? icon;

  const ScavStatusBanner(this.message, {super.key, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(children: [
      if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 8)],
      Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}

class ScavCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final Color? bgColor;
  final VoidCallback? onTap;

  const ScavCard({
    super.key, required this.child,
    this.padding, this.borderColor, this.bgColor, this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? ScavColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? ScavColors.border),
      ),
      child: child,
    ),
  );
}

class ScavChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const ScavChip(this.label, {super.key, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (dot) ...[
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
      ],
      Text(label, style: TextStyle(
        color: color, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 0.3,
      )),
    ]),
  );
}

// Type icon helper
String challengeTypeEmoji(String type) {
  switch (type) {
    case 'photo': return '📸';
    case 'text': return '💬';
    case 'location': return '📍';
    case 'location_photo': return '📍📸';
    default: return '🎯';
  }
}

String challengeTypeLabel(String type) {
  switch (type) {
    case 'photo': return 'Photo';
    case 'text': return 'Text Response';
    case 'location': return 'Location';
    case 'location_photo': return 'Location + Photo';
    default: return type;
  }
}
