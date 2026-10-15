import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

/// Colors for the glass look. Read with [GlassStyle.of] inside build methods.
class GlassStyle {
  const GlassStyle._(this.dark, this.reduced, this.accent);

  final bool dark;

  /// True when the user turned on "Reduce transparency": no blur, more solid panels.
  final bool reduced;
  final Color accent;

  static GlassStyle of(BuildContext context) {
    final settings = SettingsScope.of(context);
    return GlassStyle._(
      Theme.of(context).brightness == Brightness.dark,
      settings.reduceTransparency,
      settings.accent,
    );
  }

  Color get base => dark ? const Color(0xFF07080F) : const Color(0xFFEEF0FF);
  Color get text => dark ? const Color(0xFFF1F5F9) : const Color(0xFF24243B);
  Color get textDim => dark ? const Color(0xB3FFFFFF) : const Color(0xFF5A5A78);
  Color get border => dark ? const Color(0x29FFFFFF) : const Color(0xE6FFFFFF);
  Color get danger => dark ? const Color(0xFFFF9AA8) : const Color(0xFFB4301C);

  /// The accent color, made dark enough to read on light glass.
  Color get op {
    if (dark) return accent;
    final hsl = HSLColor.fromColor(accent);
    return hsl.withLightness(math.min(hsl.lightness, 0.3)).toColor();
  }

  /// Top and bottom color of a glass surface.
  List<Color> get fill {
    if (reduced) {
      return dark
          ? const [Color(0xFF22243A), Color(0xFF191B2E)]
          : const [Color(0xFFFFFFFF), Color(0xFFF1EEFF)];
    }
    return dark
        ? const [Color(0x33FFFFFF), Color(0x0DFFFFFF)]
        : const [Color(0xB3FFFFFF), Color(0x73FFFFFF)];
  }

  /// A glass fill tinted with [tint].
  List<Color> tinted(Color tint, {int strength = 56}) {
    final f = fill;
    return [
      Color.alphaBlend(tint.withAlpha(strength), f[0]),
      Color.alphaBlend(tint.withAlpha((strength * 0.45).round()), f[1]),
    ];
  }

  /// Gradient of the "=" key: the accent fading into a neighbouring hue.
  List<Color> get equalsGradient {
    final hsl = HSLColor.fromColor(accent);
    return [accent, hsl.withHue((hsl.hue + 90) % 360).toColor()];
  }

  /// Text color that stays readable on [equalsGradient].
  Color get onEquals {
    final mid = Color.lerp(equalsGradient[0], equalsGradient[1], 0.5)!;
    return mid.computeLuminance() > 0.4 ? const Color(0xFF04130F) : Colors.white;
  }

  List<Color> get backdropColors => dark
      ? const [Color(0xFF7C3AED), Color(0xFF0FB5A6), Color(0xFFE0388F)]
      : const [Color(0xFFFFB199), Color(0xFF8EC5FF), Color(0xFFC9A7FF)];
}

/// The soft colored background shared by every screen.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = GlassStyle.of(context);
    final overlay = (g.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _Aurora(g)),
          child,
        ],
      ),
    );
  }
}

class _Aurora extends StatelessWidget {
  const _Aurora(this.g);

  final GlassStyle g;

  Widget _blob(Color color, double size, int alpha) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withAlpha(alpha), color.withAlpha(0)]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = g.backdropColors;
    final alpha = g.dark ? 190 : 170;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: g.dark ? g.base : null,
        gradient: g.dark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE3D3), Color(0xFFE1E8FF), Color(0xFFEADBFF)],
              ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : 400.0;
          final h = box.maxHeight.isFinite ? box.maxHeight : 800.0;
          final s = math.max(w, h * 0.6);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(left: -s * 0.3, top: -s * 0.25, child: _blob(c[0], s * 1.1, alpha)),
              Positioned(right: -s * 0.4, top: h * 0.3, child: _blob(c[1], s * 1.0, alpha - 40)),
              Positioned(left: -s * 0.25, bottom: h * 0.05, child: _blob(c[2], s * 0.8, alpha - 70)),
            ],
          );
        },
      ),
    );
  }
}

/// A frosted panel. Blurs what is behind it unless transparency is reduced.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding,
    this.margin,
    this.tint,
    this.blur = 20,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final g = GlassStyle.of(context);
    final colors = tint == null ? g.fill : g.tinted(tint!);
    final r = BorderRadius.circular(radius);
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        border: Border.all(color: g.border),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
    if (!g.reduced) {
      box = ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: box,
        ),
      );
    }
    return margin == null ? box : Padding(padding: margin!, child: box);
  }
}

/// A round (or pill shaped) glass key. It never blurs, so a full keypad stays smooth.
class GlassKey extends StatelessWidget {
  const GlassKey({
    super.key,
    required this.onTap,
    required this.child,
    this.gradient,
    this.glow,
    this.tint,
    this.semanticsLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final List<Color>? gradient;
  final Color? glow;
  final Color? tint;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final g = GlassStyle.of(context);
    final colors = gradient ?? (tint != null ? g.tinted(tint!, strength: 36) : g.fill);
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: gradient == null ? Border.all(color: g.border) : null,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: glow == null ? null : [BoxShadow(color: glow!.withAlpha(110), blurRadius: 26)],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class GlassNavItem {
  const GlassNavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating glass navigation bar (row in portrait, column in landscape).
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.vertical = false,
  });

  final List<GlassNavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool vertical;

  Widget _tile(GlassStyle g, int i) {
    final item = items[i];
    final isSelected = i == selected;
    final color = isSelected ? g.op : g.textDim;
    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Container(
        height: vertical ? 60 : 52,
        width: vertical ? 72 : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isSelected ? (g.dark ? const Color(0x29FFFFFF) : const Color(0xD9FFFFFF)) : null,
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          onTap: () => onSelected(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? item.selectedIcon : item.icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassStyle.of(context);
    final tiles = [for (var i = 0; i < items.length; i++) _tile(g, i)];
    return GlassPanel(
      radius: 28,
      padding: const EdgeInsets.all(6),
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: tiles)
          : Row(children: [for (final t in tiles) Expanded(child: t)]),
    );
  }
}
