/*
 * YaMa Launcher (based on FLauncher)
 * Copyright (C) 2026
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/models/yama_settings.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flutter/material.dart';

/// Page scaffold used by YaMa's settings pages: title, divider, scrolling body.
class YamaSettingsPage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const YamaSettingsPage({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const Divider(),
      Expanded(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    ],
  );
}

class YamaSectionHeader extends StatelessWidget {
  final String text;

  const YamaSectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 14, 8, 2),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

/// A labelled dropdown. Picks the closest option when the stored value
/// isn't one of [items] so the dropdown never breaks.
class YamaDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final bool autofocus;

  const YamaDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.autofocus = false,
  });

  T get _safeValue {
    if (items.containsKey(value)) {
      return value;
    }
    final T current = value;
    if (current is num) {
      return items.keys.reduce((a, b) =>
          ((a as num) - current).abs() <= ((b as num) - current).abs() ? a : b);
    }
    return items.keys.first;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              DropdownButton<T>(
                autofocus: autofocus,
                isDense: true,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                value: _safeValue,
                items: items.entries
                    .map((entry) => DropdownMenuItem<T>(
                          value: entry.key,
                          child: Text(entry.value, style: Theme.of(context).textTheme.bodySmall),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class YamaSwitch extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool autofocus;

  const YamaSwitch({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) => RoundedSwitchListTile(
    autofocus: autofocus,
    value: value,
    onChanged: onChanged,
    title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    secondary: Icon(icon),
  );
}

/// A row of focusable color swatches from [yamaPalette].
class YamaColorPicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  /// Optional alpha to apply to the chosen color (e.g. translucent cards).
  final int? alpha;

  const YamaColorPicker({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    final int selectedRgb = value & 0x00FFFFFF;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 12),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final int color in yamaPalette)
                _Swatch(
                  color: Color(color),
                  selected: (color & 0x00FFFFFF) == selectedRgb,
                  onTap: () => onChanged(alpha == null ? color : (alpha! << 24) | (color & 0x00FFFFFF)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatefulWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({required this.color, required this.selected, required this.onTap});

  @override
  State<_Swatch> createState() => _SwatchState();
}

class _SwatchState extends State<_Swatch> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => InkWell(
    customBorder: const CircleBorder(),
    focusColor: Colors.transparent,
    onFocusChange: (focused) => setState(() => _focused = focused),
    onTap: widget.onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: _focused ? Colors.white : (widget.selected ? Colors.white70 : Colors.white24),
          width: _focused ? 3 : (widget.selected ? 2.5 : 1),
        ),
        boxShadow: _focused ? [BoxShadow(color: widget.color.withOpacity(0.7), blurRadius: 10)] : null,
      ),
      child: widget.selected ? Icon(Icons.check, size: 16, color: widget.color.computeLuminance() > 0.5 ? Colors.black : Colors.white) : null,
    ),
  );
}

/// A settings menu entry that opens another page.
class YamaNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  const YamaNavButton({super.key, required this.icon, required this.label, required this.onPressed, this.autofocus = false});

  @override
  Widget build(BuildContext context) => TextButton(
    autofocus: autofocus,
    onPressed: onPressed,
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
      ],
    ),
  );
}

String percentLabel(int value, {String zero = "Off"}) => value == 0 ? zero : "$value%";
