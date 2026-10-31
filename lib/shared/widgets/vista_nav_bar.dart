import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/themes/palette.dart';

class VistaNavItem {
  final int index;
  final IconData icon;
  final String label;
  final int badge;
  const VistaNavItem(this.index, this.icon, this.label, {this.badge = 0});
}

/// Bottom navigation shared by every role: two tabs, the role's main action
/// in the centre (in signal yellow), two tabs.
class VistaNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final ValueChanged<int> onItemTapped;
  final List<VistaNavItem> leading;
  final VistaNavItem action;
  final String actionHint;
  final List<VistaNavItem> trailing;

  const VistaNavBar({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onItemTapped,
    required this.leading,
    required this.action,
    required this.actionHint,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode;
    return Semantics(
      container: true,
      label: 'Main navigation',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.card(dark),
          border: Border(top: BorderSide(color: Palette.border(dark))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                for (final item in leading) _tab(item, dark),
                _ActionButton(
                  item: action,
                  hint: actionHint,
                  selected: selectedIndex == action.index,
                  onTap: () => _tap(action.index),
                ),
                for (final item in trailing) _tab(item, dark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _tap(int index) {
    HapticFeedback.selectionClick();
    onItemTapped(index);
  }

  Widget _tab(VistaNavItem item, bool dark) {
    final selected = selectedIndex == item.index;
    final color = selected ? Palette.brand(dark) : Palette.muted(dark);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.badge > 0
            ? '${item.label} tab, ${item.badge} waiting'
            : '${item.label} tab',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => _tap(item.index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A short bar marks the current tab so selection never relies
              // on colour alone.
              Container(
                width: 28,
                height: 3,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Badge(
                isLabelVisible: item.badge > 0,
                backgroundColor: Palette.alert,
                label: Text(item.badge > 9 ? '9+' : '${item.badge}'),
                child: Icon(item.icon, size: 26, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VistaNavItem item;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.item,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          selected: selected,
          label: item.label,
          hint: hint,
          excludeSemantics: true,
          child: Material(
            color: Palette.signal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Palette.signalDeep, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 64,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: TactileDots()),
                    Icon(item.icon, size: 30, color: Palette.onSignal),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The raised-dome grid of tactile warning paving, used as texture on the
/// app's primary action. Painted once and cached.
class TactileDots extends StatelessWidget {
  final Color color;
  final double spacing;
  const TactileDots({
    super.key,
    this.color = const Color(0x2E1B1530),
    this.spacing = 9,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _DotsPainter(color, spacing)),
    );
  }
}

class _DotsPainter extends CustomPainter {
  final Color color;
  final double spacing;
  _DotsPainter(this.color, this.spacing);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = spacing * 0.17;
    var row = 0;
    for (var y = spacing / 2; y < size.height; y += spacing, row++) {
      final offset = row.isOdd ? spacing / 2 : 0.0;
      for (var x = spacing / 2 + offset; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.color != color || old.spacing != spacing;
}
