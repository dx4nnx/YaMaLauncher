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
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/custom_icon_service.dart';
import 'package:flauncher/widgets/yama_file_browser.dart';
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
    final CustomIconService icons = context.watch<CustomIconService>();

    return YamaSettingsPage(
      title: "Layout & cards",
      children: [
        const YamaSectionHeader("Position & size"),
        YamaDropdown<AppsPosition>(
          label: "Where the apps sit",
          icon: Icons.vertical_split_outlined,
          autofocus: true,
          value: s.appsPosition,
          items: const {
            AppsPosition.top: "Top of the screen",
            AppsPosition.bottom: "Bottom (for poster wallpapers)",
          },
          onChanged: (v) => s.setValue(YamaKeys.appsPosition, v),
        ),
        YamaDropdown<int>(
          label: "Apps across the screen",
          icon: Icons.view_week_outlined,
          value: s.cardsAcross,
          items: const {
            0: "Set per category", 2: "2 (huge)", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8",
          },
          onChanged: (v) => s.setValue(YamaKeys.cardsAcross, v),
        ),
        YamaDropdown<int>(
          label: "Rows shown at once (grids)",
          icon: Icons.table_rows_outlined,
          value: s.maxVisibleRows,
          items: const {0: "All rows", 1: "1 row", 2: "2 rows", 3: "3 rows", 4: "4 rows"},
          onChanged: (v) => s.setValue(YamaKeys.maxVisibleRows, v),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 6),
          child: Text(
            "For categories set to Grid (Launcher sections). Extra rows scroll inside the grid "
            "as you move down, so the wallpaper stays visible.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        const YamaSectionHeader("Cards"),
        YamaDropdown<CardShape>(
          label: l.cardShape,
          icon: Icons.crop_square,
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
          label: "Space between rows",
          icon: Icons.table_rows_outlined,
          value: s.sectionSpacing,
          items: {for (final v in const [0, 4, 8, 12, 16, 24, 32, 48]) v: "$v"},
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
          items: _edges,
          onChanged: (v) => s.setValue(YamaKeys.marginTop, v),
        ),
        YamaDropdown<int>(
          label: "Bottom margin",
          icon: Icons.vertical_align_bottom,
          value: s.marginBottom,
          items: _edges,
          onChanged: (v) => s.setValue(YamaKeys.marginBottom, v),
        ),

        const YamaSectionHeader("Custom icons"),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 4),
          child: Text(
            "To change one app's icon, hold Select on the app and choose Change icon. "
            "Icon files named after an app (youtube.png, downloader.png, prime-video.png) are matched automatically. "
            "${_matched(context, icons)} of your apps have a custom icon.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        YamaNavButton(
          icon: Icons.drive_folder_upload_outlined,
          label: "Import icons from a folder",
          onPressed: () async {
            final String? folder = await showYamaFileBrowser(context, title: "Choose your icons folder", mode: BrowseMode.folder);
            if (folder == null) return;
            final int copied = await icons.importFolder(folder);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Imported $copied picture${copied == 1 ? "" : "s"}; ${_matched(context, icons)} apps now have a custom icon"),
              ));
            }
          },
        ),
        YamaNavButton(
          icon: Icons.apps_outlined,
          label: "Import icons with another app",
          onPressed: () async {
            final int copied = await icons.importWithApp();
            if (copied > 0 && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Imported $copied picture${copied == 1 ? "" : "s"}; ${_matched(context, icons)} apps now have a custom icon"),
              ));
            }
          },
        ),
        if (icons.folderPath != null)
          YamaNavButton(
            icon: Icons.usb,
            label: "Copy icons with ADB",
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Copy icons with ADB"),
                content: SelectableText(
                  "Name each picture after the app, e.g. youtube.png, downloader.png or prime-video.png "
                  "(or its package name, shown when you hold Select on an app).\n\n"
                  "From your PC (platform-tools folder):\n"
                  "adb push \"C:\\Users\\you\\Downloads\\icons\\.\" ${icons.folderPath}/\n\n"
                  "Icons already on the TV's Downloads folder:\n"
                  "adb shell cp /sdcard/Download/*.png ${icons.folderPath}/\n\n"
                  "Then choose \"Reload custom icons\". PNG, JPG and WEBP work.",
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")),
                ],
              ),
            ),
          ),
        YamaNavButton(
          icon: Icons.refresh,
          label: "Reload custom icons",
          onPressed: () async {
            final int found = await icons.reload();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$found custom icon${found == 1 ? "" : "s"} found")),
              );
            }
          },
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

  static const Map<int, String> _edges = {
    0: "0", 8: "8", 16: "16", 24: "24", 32: "32", 48: "48", 64: "64", 96: "96", 128: "128", 192: "192", 256: "256",
  };

  static const Map<int, String> _margins = {
    0: "0", 16: "16", 32: "32", 48: "48", 64: "64", 96: "96", 128: "128", 192: "192",
  };

  static int _matched(BuildContext context, CustomIconService icons) => icons.matchCount(
        context.read<AppsService>().applications.map((app) => (packageName: app.packageName, name: app.name)),
      );
}
