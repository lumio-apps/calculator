import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

/// Colors and shadows for the soft (neumorphic) look.
/// Read with [NeoStyle.of] inside build methods.
class NeoStyle {
  const NeoStyle._(this.dark, this.flat, this.accent);

  final bool dark;

  /// True when the user turned on "Reduce effects": no soft shadows, flat outlined panels.
  final bool flat;
  final Color accent;

  static NeoStyle of(BuildContext context) {
    final settings = SettingsScope.of(context);
    return NeoStyle._(
      Theme.of(context).brightness == Brightness.dark,
      settings.reduceEffects,
      settings.accent,
    );
  }

  Color get bg => dark ? const Color(0xFF22262F) : const Color(0xFFE4E9F1);
  Color get text => dark ? const Color(0xFFE8ECF5) : const Color(0xFF2E3650);
  Color get textDim => dark ? const Color(0xFFA5ADC4) : const Color(0xFF5A6280);
  Color get danger => dark ? const Color(0xFFFF9A8B) : const Color(0xFFC0392B);

  /// The shadow on the dark side of a raised shape.
  Color get shadowDark => dark ? const Color(0xFF14161C) : const Color(0xFFB3BED0);

  /// The highlight on the light side of a raised shape.
  Color get shadowLight => dark ? const Color(0xFF2F3441) : const Color(0xFFFFFFFF);

  /// Outline used when effects are reduced.
  Color get outline => dark ? const Color(0x40FFFFFF) : const Color(0x4D7C8AA8);

  /// Surface color used when effects are reduced.
  Color get flatFill => dark ? const Color(0xFF2A2E39) : const Color(0xFFF2F5FA);

  /// The accent color, made dark enough to read on the light surface.
  Color get op {
    if (dark) return accent;
    final hsl = HSLColor.fromColor(accent);
    return hsl.withLightness(math.min(hsl.lightness, 0.3)).toColor();
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
}

bool _reduceMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;

/// The plain background shared by every screen.
class NeoBackdrop extends StatelessWidget {
  const NeoBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    final overlay = (g.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: ColoredBox(color: g.bg, child: child),
    );
  }
}

/// Paints soft shadows on the inside of a rounded shape, so it looks pressed in.
class _InsetPainter extends CustomPainter {
  const _InsetPainter({
    required this.radius,
    required this.dark,
    required this.light,
    required this.offset,
    required this.blur,
  });

  final double radius;
  final Color dark;
  final Color light;
  final double offset;
  final double blur;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(radius, math.min(size.width, size.height) / 2);
    final shape = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));
    final outer = Path()..addRect(Rect.fromLTWH(-80, -80, size.width + 160, size.height + 160));
    final frame = Path.combine(PathOperation.difference, outer, Path()..addRRect(shape));
    final mask = MaskFilter.blur(BlurStyle.normal, blur / 2);

    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawPath(
      frame.shift(Offset(offset, offset)),
      Paint()
        ..color = dark
        ..maskFilter = mask,
    );
    canvas.drawPath(
      frame.shift(Offset(-offset, -offset)),
      Paint()
        ..color = light
        ..maskFilter = mask,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetPainter old) =>
      old.radius != radius ||
      old.dark != dark ||
      old.light != light ||
      old.offset != offset ||
      old.blur != blur;
}

/// A soft surface. [press] goes from 0 (raised) to 1 (pressed in).
class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.radius = 28,
    this.press = 0,
    this.fill,
    this.gradient,
    this.glow,
    this.glowStrength = 0,
    this.small = false,
  });

  final Widget child;
  final double radius;
  final double press;
  final Color? fill;
  final List<Color>? gradient;
  final Color? glow;
  final double glowStrength;

  /// Smaller shadows for small shapes such as icon buttons.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    final r = BorderRadius.circular(radius);

    if (g.flat) {
      final base = fill ?? Color.lerp(g.flatFill, g.bg, press)!;
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          color: gradient == null ? base : null,
          gradient: gradient == null
              ? null
              : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient!),
          border: Border.all(color: g.outline),
        ),
        child: child,
      );
    }

    final dist = small ? 4.0 : 6.0;
    final blur = small ? 10.0 : 14.0;
    final clear = Colors.transparent;
    final shadows = <BoxShadow>[
      BoxShadow(
        color: Color.lerp(g.shadowDark, clear, press)!,
        offset: Offset(dist, dist),
        blurRadius: blur,
      ),
      BoxShadow(
        color: Color.lerp(g.shadowLight, clear, press)!,
        offset: Offset(-dist, -dist),
        blurRadius: blur,
      ),
      if (glow != null && glowStrength > 0)
        BoxShadow(
          color: glow!.withAlpha(math.max(0, math.min(255, (120 * glowStrength * (1 - press)).round()))),
          blurRadius: 26,
          spreadRadius: 2,
        ),
    ];

    Widget inner = child;
    if (press > 0) {
      inner = CustomPaint(
        painter: _InsetPainter(
          radius: radius,
          dark: Color.lerp(clear, g.shadowDark, press)!,
          light: Color.lerp(clear, g.shadowLight, press)!,
          offset: small ? 3.5 : 5,
          blur: small ? 8 : 11,
        ),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        color: gradient == null ? (fill ?? g.bg) : null,
        gradient: gradient == null
            ? null
            : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient!),
        boxShadow: shadows,
      ),
      child: inner,
    );
  }
}

/// A resting panel: raised by default, or pressed in with [inset].
class NeoPanel extends StatelessWidget {
  const NeoPanel({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding,
    this.margin,
    this.tint,
    this.inset = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    final fill = tint == null ? null : Color.alphaBlend(tint!.withAlpha(g.dark ? 22 : 30), g.bg);
    final box = RepaintBoundary(
      child: NeoSurface(
        radius: radius,
        press: inset ? 1 : 0,
        fill: fill,
        child: Material(
          type: MaterialType.transparency,
          child: padding == null ? child : Padding(padding: padding!, child: child),
        ),
      ),
    );
    return margin == null ? box : Padding(padding: margin!, child: box);
  }
}

/// Tap handling shared by keys, cards and icon buttons: sinks in while pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.builder, this.scaleDown = 0.05});

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, double press) builder;
  final double scaleDown;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _release() {
    // Keep the pressed look visible for a moment, even on very quick taps.
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _down = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => _release(),
      onTapCancel: widget.onTap == null ? null : _release,
      onTap: widget.onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _down ? 1 : 0),
        duration: Duration(milliseconds: reduce ? 0 : 160),
        curve: Curves.easeOut,
        builder: (context, t, _) => Transform.scale(
          scale: 1 - widget.scaleDown * t,
          child: widget.builder(context, t),
        ),
      ),
    );
  }
}

/// A round (or pill shaped) key. It sinks in when pressed. The "=" key can breathe with a glow.
class NeoKey extends StatefulWidget {
  const NeoKey({
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
  State<NeoKey> createState() => _NeoKeyState();
}

class _NeoKeyState extends State<NeoKey> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.glow != null) _breath.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    final reduce = _reduceMotion(context);
    final fill = widget.tint == null ? null : Color.alphaBlend(widget.tint!.withAlpha(g.dark ? 26 : 34), g.bg);

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      child: RepaintBoundary(
        child: _Pressable(
          onTap: widget.onTap,
          builder: (context, press) {
            return AnimatedBuilder(
              animation: _breath,
              builder: (context, _) => NeoSurface(
                radius: 999,
                press: press,
                fill: fill,
                gradient: widget.gradient,
                glow: widget.glow,
                glowStrength: g.flat ? 0 : (reduce ? 0.4 : _breath.value),
                child: Center(child: widget.child),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A raised card that sinks in when pressed (used for the list of tools).
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 26,
    this.margin,
  });

  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = RepaintBoundary(
      child: _Pressable(
        onTap: onTap,
        scaleDown: 0.025,
        builder: (context, press) => NeoSurface(
          radius: radius,
          press: press,
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}

/// A small round raised button for headers.
class NeoIconButton extends StatelessWidget {
  const NeoIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    final button = Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: tooltip != null,
      child: _Pressable(
        onTap: onPressed,
        scaleDown: 0.06,
        builder: (context, press) => NeoSurface(
          radius: 22,
          small: true,
          press: press,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: g.textDim),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The same round look as [NeoIconButton], for places that handle the tap themselves (such as a popup menu).
class NeoCircleIcon extends StatelessWidget {
  const NeoCircleIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: NeoSurface(
        radius: 22,
        small: true,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: g.textDim),
        ),
      ),
    );
  }
}

class NeoNavItem {
  const NeoNavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating navigation bar: a pressed-in track with a raised pill that slides to the chosen tab.
class NeoNavBar extends StatelessWidget {
  const NeoNavBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.vertical = false,
  });

  final List<NeoNavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool vertical;

  Widget _tile(NeoStyle g, bool reduce, int i, double w, double h) {
    final item = items[i];
    final isSelected = i == selected;
    final color = isSelected ? g.op : g.textDim;
    final fast = Duration(milliseconds: reduce ? 0 : 280);
    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(i),
        child: SizedBox(
          width: w,
          height: h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.12 : 1,
                duration: fast,
                curve: Curves.easeOutBack,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: fast,
                  builder: (context, c, _) => Icon(isSelected ? item.selectedIcon : item.icon, size: 22, color: c),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: fast,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(item.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    final reduce = _reduceMotion(context);
    final n = items.length;
    final tileH = vertical ? 60.0 : 52.0;

    return NeoPanel(
      inset: true,
      radius: 28,
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, box) {
          final tileW = vertical ? 72.0 : box.maxWidth / n;
          final pill = AnimatedPositioned(
            duration: Duration(milliseconds: reduce ? 0 : 420),
            curve: const Cubic(0.25, 1.1, 0.35, 1.0),
            left: vertical ? 0 : selected * tileW,
            top: vertical ? selected * tileH : 0,
            width: tileW,
            height: tileH,
            child: const NeoSurface(radius: 22, small: true, child: SizedBox.expand()),
          );
          final tiles = [for (var i = 0; i < n; i++) _tile(g, reduce, i, tileW, tileH)];
          return SizedBox(
            width: vertical ? tileW : box.maxWidth,
            height: vertical ? tileH * n : tileH,
            child: Stack(
              children: [
                pill,
                vertical ? Column(children: tiles) : Row(children: tiles),
              ],
            ),
          );
        },
      ),
    );
  }
}
