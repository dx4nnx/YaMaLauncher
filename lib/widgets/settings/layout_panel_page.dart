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

import 'package:flauncher/models/layout_options.dart';
import 'package:flauncher/models/yama_settings.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/yama_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Cards, spacing, margins and the glass dock behind categories.
class LayoutPanelPage extends StatelessWidget {
  static const String routeName = "layout_panel";

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final SettingsService s = context.watch<SettingsService>();

    return YamaSettingsPage(
      title: "Layout & cards",
      children: [
        const YamaSectionHeader("Cards"),
        YamaDropdown<CardShape>(
          label: l.cardShape,
          icon: Icons.crop_square,
          autofocus: true,
          value: s.cardShape,
          items: {
            CardShape.banner: l.cardShapeBanner,
            CardShape.square: l.cardShapeSquare,
            CardShape.circle: l.cardShapeCircle,
          },
          onChanged: s.setCardShape,
        ),
        YamaDropdown<LabelMode>(
          label: l.appNames,
          icon: Icons.short_text,
          value: s.labelMode,
          items: {
            LabelMode.never: l.appNamesNever,
            LabelMode.focused: l.appNamesFocused,
            LabelMode.always: l.appNamesAlways,
          },
          onChanged: s.setLabelMode,
        ),
        YamaDropdown<double>(
          label: l.focusZoom,
          icon: Icons.zoom_in,
          value: s.focusZoom,
          items: {
            for (final zoom in const [1.0, 1.05, 1.1, 1.15, 1.2, 1.3])
              zoom: zoom == 1.0 ? l.off : "${((zoom - 1) * 100).round()}%",
          },
          onChanged: s.setFocusZoom,
        ),
        YamaDropdown<int>(
          label: l.cornerRadius,
          icon: Icons.rounded_corner,
          value: s.cornerRadius,
          items: {for (final r in const [0, 4, 8, 12, 16, 20, 24, 32]) r: r == 0 ? l.off : "$r"},
          onChanged: s.setCornerRadius,
        ),
        YamaColorPicker(
          label: "Icon card background",
          icon: Icons.format_color_fill,
          value: s.iconCardColor,
          alpha: (s.iconCardColor >> 24) & 0xFF,
          onChanged: (color) => s.setValue(YamaKeys.iconCardColor, color),
        ),
        YamaDropdown<int>(
          label: "Icon card see-through",
          icon: Icons.opacity,
          value: 100 - (((s.iconCardColor >> 24) & 0xFF) * 100 / 255).round(),
          items: {for (final p in const [0, 20, 40, 60, 70, 80, 90, 100]) p: "$p%"},
          onChanged: (percent) {
            final int alpha = ((100 - percent) * 255 / 100).round().clamp(0, 255).toInt();
            s.setValue(YamaKeys.iconCardColor, (alpha << 24) | (s.iconCardColor & 0x00FFFFFF));
          },
        ),

        const YamaSectionHeader("Spacing"),
        YamaDropdown<int>(
          label: l.cardSpacing,
          icon: Icons.view_column_outlined,
          value: s.cardSpacing,
          items: {for (final v in const [4, 8, 12, 16, 20, 24, 32, 40]) v: "$v"},
          onChanged: s.setCardSpacing,
        ),
        YamaDropdown<int>(
          label: l.sectionSpacing,
          icon: Icons.table_rows_outlined,
          value: s.sectionSpacing,
          items: {for (final v in const [0, 8, 16, 24, 32, 48]) v: "$v"},
          onChanged: s.setSectionSpacing,
        ),
        YamaDropdown<int>(
          label: "Left margin",
          icon: Icons.format_indent_increase,
          value: s.marginLeft,
          items: _margins,
          onChanged: (v) => s.setValue(YamaKeys.marginLeft, v),
        ),
        YamaDropdown<int>(
          label: "Right margin",
          icon: Icons.format_indent_decrease,
          value: s.marginRight,
          items: _margins,
          onChanged: (v) => s.setValue(YamaKeys.marginRight, v),
        ),
        YamaDropdown<int>(
          label: "Top margin",
          icon: Icons.vertical_align_top,
          value: s.marginTop,
          items: {for (final v in const [0, 16, 32, 64, 96, 128, 192, 256]) v: v == 0 ? l.off : "$v"},
          onChanged: (v) => s.setValue(YamaKeys.marginTop, v),
        ),

        const YamaSectionHeader("Categories"),
        YamaSwitch(
          label: l.showCategoryTitles,
          icon: Icons.title,
          value: s.showCategoryTitles,
          onChanged: s.setShowCategoryTitles,
        ),
        YamaSwitch(
          label: "Hide empty categories",
          icon: Icons.visibility_off_outlined,
          value: s.hideEmptyCategories,
          onChanged: (v) => s.setValue(YamaKeys.hideEmptyCategories, v),
        ),
        YamaSwitch(
          label: "Glass dock behind categories",
          icon: Icons.dock_outlined,
          value: s.dockEnabled,
          onChanged: (v) => s.setValue(YamaKeys.dockEnabled, v),
        ),
        if (s.dockEnabled) ...[
          YamaDropdown<int>(
            label: "Dock brightness",
            icon: Icons.light_mode_outlined,
            value: s.dockOpacity,
            items: {for (final v in const [4, 6, 8, 10, 14, 18, 24, 32]) v: "$v%"},
            onChanged: (v) => s.setValue(YamaKeys.dockOpacity, v),
          ),
          YamaSwitch(
            label: "Frosted dock (uses more power)",
            icon: Icons.blur_on,
            value: s.dockBlur,
            onChanged: (v) => s.setValue(YamaKeys.dockBlur, v),
          ),
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(l.cardSizeHint, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  static const Map<int, String> _margins = {
    0: "0", 16: "16", 32: "32", 48: "48", 64: "64", 96: "96", 128: "128", 192: "192",
  };
}
