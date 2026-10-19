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
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/yama_controls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// How the selected app card stands out: glow, shadow, tint and dimming.
class FocusPanelPage extends StatelessWidget {
  static const String routeName = "focus_panel";

  @override
  Widget build(BuildContext context) {
    final SettingsService s = context.watch<SettingsService>();

    return YamaSettingsPage(
      title: "Focus effects",
      children: [
        YamaDropdown<FocusEffect>(
          label: "Selected card effect",
          icon: Icons.auto_awesome,
          autofocus: true,
          value: s.focusEffect,
          items: const {
            FocusEffect.glow: "Glow",
            FocusEffect.shadow: "Drop shadow",
            FocusEffect.none: "None",
          },
          onChanged: (v) => s.setValue(YamaKeys.focusEffect, v),
        ),
        if (s.focusEffect == FocusEffect.glow) ...[
          YamaColorPicker(
            label: "Glow color",
            icon: Icons.palette_outlined,
            value: s.glowColor,
            onChanged: (v) => s.setValue(YamaKeys.glowColor, v),
          ),
          YamaDropdown<int>(
            label: "Glow size",
            icon: Icons.lens_blur,
            value: s.glowSize,
            items: const {4: "Tiny", 8: "Small", 12: "Medium", 16: "Large", 24: "Huge"},
            onChanged: (v) => s.setValue(YamaKeys.glowSize, v),
          ),
          YamaDropdown<GlowAnimation>(
            label: "Glow animation",
            icon: Icons.animation,
            value: s.glowAnimation,
            items: const {
              GlowAnimation.breathe: "Breathe (slow)",
              GlowAnimation.pulse: "Pulse (fast)",
              GlowAnimation.shimmer: "Shimmer (color shift)",
              GlowAnimation.still: "Still",
            },
            onChanged: (v) => s.setValue(YamaKeys.glowAnimation, v),
          ),
        ],
        const YamaSectionHeader("Selected card tint"),
        YamaDropdown<int>(
          label: "Tint strength",
          icon: Icons.gradient,
          value: s.focusTintStrength,
          items: {for (final v in const [0, 10, 20, 30, 40, 60]) v: percentLabel(v)},
          onChanged: (v) => s.setValue(YamaKeys.focusTintStrength, v),
        ),
        if (s.focusTintStrength > 0)
          YamaColorPicker(
            label: "Tint color",
            icon: Icons.colorize,
            value: s.focusTintColor,
            onChanged: (v) => s.setValue(YamaKeys.focusTintColor, v),
          ),
        const YamaSectionHeader("Other cards"),
        YamaDropdown<int>(
          label: "Dim cards that aren't selected",
          icon: Icons.brightness_low,
          value: s.unfocusedDim,
          items: {for (final v in const [0, 6, 12, 20, 30, 40, 55]) v: percentLabel(v)},
          onChanged: (v) => s.setValue(YamaKeys.unfocusedDim, v),
        ),
        YamaSwitch(
          label: "Animate the selected card",
          icon: Icons.filter_center_focus,
          value: s.appHighlightAnimationEnabled,
          onChanged: s.setAppHighlightAnimationEnabled,
        ),
      ],
    );
  }
}
