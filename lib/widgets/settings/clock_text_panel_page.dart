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
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/yama_controls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Clock look, fonts, text size and the accent color.
class ClockTextPanelPage extends StatelessWidget {
  static const String routeName = "clock_text_panel";

  @override
  Widget build(BuildContext context) {
    final SettingsService s = context.watch<SettingsService>();

    return YamaSettingsPage(
      title: "Clock & text",
      children: [
        const YamaSectionHeader("Clock"),
        YamaDropdown<int>(
          label: "Clock size",
          icon: Icons.format_size,
          autofocus: true,
          value: s.clockSize,
          items: const {16: "Small", 20: "Compact", 24: "Medium", 30: "Large", 38: "Extra large", 48: "Huge"},
          onChanged: (v) => s.setValue(YamaKeys.clockSize, v),
        ),
        YamaSwitch(
          label: "Two lines (time above date)",
          icon: Icons.view_agenda_outlined,
          value: s.clockTwoLines,
          onChanged: (v) => s.setValue(YamaKeys.clockTwoLines, v),
        ),
        YamaSwitch(
          label: "Soft shadow behind clock",
          icon: Icons.blur_circular,
          value: s.clockShadow,
          onChanged: (v) => s.setValue(YamaKeys.clockShadow, v),
        ),
        YamaColorPicker(
          label: "Clock color",
          icon: Icons.palette_outlined,
          value: s.clockColor,
          onChanged: (v) => s.setValue(YamaKeys.clockColor, v),
        ),
        YamaNavButton(
          icon: Icons.tips_and_updates_outlined,
          label: "Status bar (date, time, auto-hide)",
          onPressed: () => Navigator.of(context).pushNamed(StatusBarPanelPage.routeName),
        ),

        const YamaSectionHeader("Text"),
        YamaDropdown<String>(
          label: "Font",
          icon: Icons.font_download_outlined,
          value: s.fontFamily,
          items: {for (final font in yamaFonts) font: font == "System" ? "System default" : font},
          onChanged: (v) => s.setValue(YamaKeys.fontFamily, v),
        ),
        YamaDropdown<int>(
          label: "Text size",
          icon: Icons.text_fields,
          value: s.textScale,
          items: const {80: "Small", 90: "Slightly small", 100: "Normal", 115: "Large", 130: "Extra large"},
          onChanged: (v) => s.setValue(YamaKeys.textScale, v),
        ),
        YamaColorPicker(
          label: "Accent color (menus & switches)",
          icon: Icons.color_lens_outlined,
          value: s.accentColor,
          onChanged: (v) => s.setValue(YamaKeys.accentColor, v),
        ),
      ],
    );
  }
}
