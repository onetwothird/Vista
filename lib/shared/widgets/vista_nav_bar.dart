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
/// in the centre, two tabs.
///
/// Every slot has the same shape (a pill holding the icon, a label below), so
/// the bar reads as one row. The current tab's pill is a soft navy wash; the
/// centre action's pill is solid navy, like the app's main buttons.
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
            height: 76,
            child: Row(
              children: [
                for (final item in leading) _slot(item, dark),
                _slot(action, dark, isAction: true),
                for (final item in trailing) _slot(item, dark),
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

  Widget _slot(VistaNavItem item, bool dark, {bool isAction = false}) {
    final selected = selectedIndex == item.index;
    final Color pill;
    final Color iconColor;
    final Color labelColor;
    if (isAction) {
      // Same pairing as the main buttons: navy by day, honey by night.
      pill = dark ? Palette.honey : Palette.violet;
      iconColor = dark ? Palette.violetDeep : Colors.white;
      labelColor = Palette.text(dark);
    } else if (selected) {
      pill = dark ? Palette.violetTintNight : Palette.violetTint;
      iconColor = Palette.brand(dark);
      labelColor = Palette.text(dark);
    } else {
      pill = Colors.transparent;
      iconColor = Palette.muted(dark);
      labelColor = Palette.muted(dark);
    }

    final String label;
    if (isAction) {
      label = item.label;
    } else {
      label = item.badge > 0
          ? '${item.label} tab, ${item.badge} waiting'
          : '${item.label} tab';
    }

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        hint: isAction ? actionHint : null,
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => _tap(item.index),
          radius: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: isAction ? 60 : 56,
                height: 34,
                decoration: BoxDecoration(
                  color: pill,
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Badge(
                  isLabelVisible: item.badge > 0,
                  backgroundColor: Palette.alert,
                  label: Text(item.badge > 9 ? '9+' : '${item.badge}'),
                  child: Icon(item.icon, size: 24, color: iconColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  color: labelColor,
                  fontWeight: selected || isAction
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
