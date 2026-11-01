import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seelai_app/shared/accessibility.dart';
import 'package:seelai_app/themes/palette.dart';
import 'package:seelai_app/themes/vista_theme.dart';

/// Settings that make Vista easier to see and hear: text size (with a live
/// preview), bold text, high contrast, dark mode, reduce motion, and how fast
/// Vista reads aloud. Changes apply across the app straight away.
class AccessibilityPanel extends StatefulWidget {
  final bool isDarkMode;

  const AccessibilityPanel({super.key, required this.isDarkMode});

  @override
  State<AccessibilityPanel> createState() => _AccessibilityPanelState();
}

class _AccessibilityPanelState extends State<AccessibilityPanel> {
  final _tts = FlutterTts();

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _tryVoice() async {
    await _tts.stop();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(a11y.speechRate);
    await _tts.speak('Hi, I am Vista. This is how fast I will read to you.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([a11y, themeController]),
      builder: (context, _) {
        final dark = widget.isDarkMode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TextSizeBlock(dark: dark),
            _divider(dark),
            _Toggle(
              icon: Icons.format_bold_rounded,
              title: 'Bold text',
              subtitle: 'Thicker letters everywhere',
              value: a11y.boldText,
              onChanged: (v) => a11y.boldText = v,
              dark: dark,
            ),
            _divider(dark),
            _Toggle(
              icon: Icons.contrast_rounded,
              title: 'High contrast',
              subtitle: 'Darker text and sharper outlines',
              value: a11y.highContrast,
              onChanged: (v) => a11y.highContrast = v,
              dark: dark,
            ),
            _divider(dark),
            _Toggle(
              icon: Icons.dark_mode_outlined,
              title: 'Dark mode',
              subtitle: 'Light text on a dark page, less glare',
              value: themeController.value,
              onChanged: (v) => themeController.set(v),
              dark: dark,
            ),
            _divider(dark),
            _Toggle(
              icon: Icons.motion_photos_off_outlined,
              title: 'Reduce motion',
              subtitle: 'Fewer moving animations',
              value: a11y.reduceMotion,
              onChanged: (v) => a11y.reduceMotion = v,
              dark: dark,
            ),
            _divider(dark),
            _SpeechBlock(dark: dark, onTry: _tryVoice),
          ],
        );
      },
    );
  }

  Widget _divider(bool dark) => Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: Palette.border(dark).withValues(alpha: 0.6),
  );
}

class _TextSizeBlock extends StatelessWidget {
  const _TextSizeBlock({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final steps = A11ySettings.textSteps.entries.toList();
    final current = a11y.textScale;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: Icons.text_fields_rounded, dark: dark),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Text size',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Palette.text(dark),
                  ),
                ),
              ),
              Text(
                A11ySettings.textSteps[current] ?? 'Custom',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Palette.brand(dark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Live preview at the chosen size.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.raised(dark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Vista reads signs, labels and faces for you.',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _SizeChip(
                    // Bigger letter for bigger steps, but kept out of the
                    // app scale so the row always fits.
                    letterSize: 14.0 + i * 3.5,
                    label: steps[i].value,
                    selected: (current - steps[i].key).abs() < 0.01,
                    onTap: () => a11y.textScale = steps[i].key,
                    dark: dark,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.letterSize,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.dark,
  });

  final double letterSize;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Palette.brand(dark) : Palette.raised(dark);
    final fg = selected
        ? (dark ? Palette.violetDeep : Colors.white)
        : Palette.text(dark);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Text size $label',
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: MediaQuery.withNoTextScaling(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: letterSize,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechBlock extends StatelessWidget {
  const _SpeechBlock({required this.dark, required this.onTry});

  final bool dark;
  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    final steps = A11ySettings.speechSteps.entries.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: Icons.record_voice_over_outlined, dark: dark),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Reading speed',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Palette.text(dark),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onTry,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Try it'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<double>(
              showSelectedIcon: false,
              segments: [
                for (final s in steps)
                  ButtonSegment(value: s.key, label: Text(s.value)),
              ],
              selected: {
                steps
                    .reduce(
                      (a, b) =>
                          (a.key - a11y.speechRate).abs() <=
                              (b.key - a11y.speechRate).abs()
                          ? a
                          : b,
                    )
                    .key,
              },
              onSelectionChanged: (v) => a11y.speechRate = v.first,
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.dark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              _IconTile(icon: icon, dark: dark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Palette.text(dark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Palette.muted(dark),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.dark});

  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: dark ? Palette.violetTintNight : Palette.violetTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: Palette.brand(dark)),
    );
  }
}
