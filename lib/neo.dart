import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

/// Colors for the light, flat look: plain surfaces with a thin border, no blurred shadows.
/// Read with [NeoStyle.of] inside build methods.
class NeoStyle {
  const NeoStyle._(this.dark, this.accent);

  final bool dark;
  final Color accent;

  static NeoStyle of(BuildContext context) {
    final settings = SettingsScope.of(context);
    return NeoStyle._(Theme.of(context).brightness == Brightness.dark, settings.accent);
  }

  /// Page background.
  Color get bg => dark ? const Color(0xFF14161C) : const Color(0xFFF4F6FA);

  /// Keys, cards and panels.
  Color get key => dark ? const Color(0xFF1E222B) : const Color(0xFFFFFFFF);

  /// Thin border around surfaces.
  Color get line => dark ? const Color(0xFF2B303C) : const Color(0xFFE1E6EF);

  /// Color of a surface while it is pressed.
  Color get pressed => dark ? const Color(0xFF2A2F3A) : const Color(0xFFE8ECF4);

  Color get text => dark ? const Color(0xFFF1F3F8) : const Color(0xFF1E2433);
  Color get textDim => dark ? const Color(0xFFA3ABBD) : const Color(0xFF5C6579);
  Color get danger => dark ? const Color(0xFFFF8A80) : const Color(0xFFC62D2D);

  /// The accent color, made dark enough to read on the light surface.
  Color get op {
    if (dark) return accent;
    final hsl = HSLColor.fromColor(accent);
    return hsl.withLightness(math.min(hsl.lightness, 0.3)).toColor();
  }

  /// A soft tint of the accent, for icon backgrounds and the selected tab.
  Color get soft => Color.alphaBlend(accent.withAlpha(dark ? 40 : 52), key);

  /// Fill of the "=" key.
  Color get equalsFill => accent;

  /// Text color that stays readable on [equalsFill].
  Color get onEquals => accent.computeLuminance() > 0.4 ? const Color(0xFF04130F) : Colors.white;
}

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

/// A resting panel with a thin border. With [inset] it is filled with a soft tint instead.
class NeoPanel extends StatelessWidget {
  const NeoPanel({
    super.key,
    required this.child,
    this.radius = 20,
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
    final r = math.min(radius, 24.0);
    final Color fill;
    if (tint != null) {
      fill = Color.alphaBlend(tint!.withAlpha(g.dark ? 28 : 36), g.key);
    } else {
      fill = inset ? g.soft : g.key;
    }
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(r),
        border: inset ? null : Border.all(color: g.line),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
    return margin == null ? box : Padding(padding: margin!, child: box);
  }
}

/// A tappable surface. Pressing it only changes its color.
class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.onTap,
    required this.child,
    required this.radius,
    this.fill,
    this.pressedFill,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  final Color? fill;
  final Color? pressedFill;

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: fill == null ? g.line : Colors.transparent),
    );
    return Material(
      color: fill ?? g.key,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: pressedFill ?? g.pressed,
        child: child,
      ),
    );
  }
}

/// A rounded key. [fill] gives it a solid color (used by the "=" key).
class NeoKey extends StatelessWidget {
  const NeoKey({
    super.key,
    required this.onTap,
    required this.child,
    this.fill,
    this.semanticsLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? fill;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: _Tappable(
        onTap: onTap,
        radius: 20,
        fill: fill,
        pressedFill: fill == null ? null : Color.lerp(fill, Colors.black, 0.12),
        child: Center(child: child),
      ),
    );
  }
}

/// A card for the list of tools.
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 18,
    this.margin,
  });

  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = _Tappable(onTap: onTap, radius: radius, child: child);
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}

/// A small rounded button for headers.
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
      child: _Tappable(
        onTap: onPressed,
        radius: 14,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: g.textDim),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The same look as [NeoIconButton], for places that handle the tap themselves (such as a popup menu).
class NeoCircleIcon extends StatelessWidget {
  const NeoCircleIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final g = NeoStyle.of(context);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: g.key,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: g.line),
        ),
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

/// Navigation bar with a thin border. The chosen tab just changes color.
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

  Widget _tile(NeoStyle g, int i) {
    final item = items[i];
    final isSelected = i == selected;
    final color = isSelected ? g.op : g.textDim;
    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(i),
        child: SizedBox(
          height: 56,
          width: vertical ? 76 : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? g.soft : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(isSelected ? item.selectedIcon : item.icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    final g = NeoStyle.of(context);
    final tiles = [
      for (var i = 0; i < items.length; i++) vertical ? _tile(g, i) : Expanded(child: _tile(g, i)),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: g.bg,
        border: vertical
            ? Border(right: BorderSide(color: g.line))
            : Border(top: BorderSide(color: g.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, vertical ? 8 : 6, 4, vertical ? 8 : 6),
        child: vertical ? Column(mainAxisSize: MainAxisSize.min, children: tiles) : Row(children: tiles),
      ),
    );
  }
}
