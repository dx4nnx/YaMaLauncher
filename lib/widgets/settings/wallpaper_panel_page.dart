/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 * YaMa Launcher changes Copyright (C) 2026
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
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/settings/gradient_panel_page.dart';
import 'package:flauncher/widgets/settings/yama_controls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WallpaperPanelPage extends StatelessWidget {
  static const String routeName = "wallpaper_panel";

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final SettingsService s = context.watch<SettingsService>();
    final WallpaperService wallpaper = context.watch<WallpaperService>();

    return YamaSettingsPage(
      title: localizations.wallpaper,
      children: [
        const YamaSectionHeader("Source"),
        YamaDropdown<WallpaperMode>(
          label: "Show",
          icon: Icons.wallpaper,
          autofocus: true,
          value: s.wallpaperMode,
          items: {
            WallpaperMode.gradient: localizations.gradient,
            WallpaperMode.solid: "Solid color",
            if (wallpaper.wallpaper != null || s.wallpaperMode == WallpaperMode.image)
              WallpaperMode.image: localizations.picture,
            if (wallpaper.slideCount > 0 || s.wallpaperMode == WallpaperMode.slideshow)
              WallpaperMode.slideshow: "Slideshow (${wallpaper.slideCount})",
          },
          onChanged: wallpaper.useMode,
        ),
        YamaNavButton(
          icon: Icons.gradient,
          label: "Choose a gradient",
          onPressed: () => Navigator.of(context).pushNamed(GradientPanelPage.routeName),
        ),
        YamaNavButton(
          icon: Icons.image_outlined,
          label: "Choose a picture",
          onPressed: () => _guard(context, () => wallpaper.pickWallpaper()),
        ),
        YamaNavButton(
          icon: Icons.collections_outlined,
          label: "Add pictures to slideshow",
          onPressed: () => _guard(context, () async {
            final int added = await wallpaper.addSlideshowPictures();
            if (added > 0 && context.mounted) {
              _toast(context, "Added $added picture${added == 1 ? "" : "s"} to the slideshow");
            }
          }),
        ),
        if (s.wallpaperMode == WallpaperMode.solid)
          YamaColorPicker(
            label: "Solid color",
            icon: Icons.format_paint_outlined,
            value: s.wallpaperSolidColor,
            onChanged: (v) => wallpaper.setSolidColor(Color(v)),
          ),

        if (wallpaper.slideCount > 0) ...[
          const YamaSectionHeader("Slideshow"),
          YamaDropdown<int>(
            label: "Change picture every",
            icon: Icons.timer_outlined,
            value: s.slideshowInterval,
            items: const {
              15: "15 seconds", 30: "30 seconds", 60: "1 minute", 300: "5 minutes",
              900: "15 minutes", 1800: "30 minutes", 3600: "1 hour", 21600: "6 hours",
            },
            onChanged: (v) => s.setValue(YamaKeys.slideshowInterval, v),
          ),
          YamaDropdown<SlideEffect>(
            label: "Transition",
            icon: Icons.slideshow,
            value: s.slideshowTransition,
            items: const {
              SlideEffect.fade: "Fade",
              SlideEffect.zoom: "Zoom",
              SlideEffect.slideHorizontal: "Slide sideways",
              SlideEffect.slideVertical: "Slide up",
              SlideEffect.random: "Random",
            },
            onChanged: (v) => s.setValue(YamaKeys.slideshowTransition, v),
          ),
          YamaNavButton(
            icon: Icons.skip_next_outlined,
            label: "Next picture now (or press Play/Pause)",
            onPressed: wallpaper.nextWallpaper,
          ),
          YamaNavButton(
            icon: Icons.delete_outline,
            label: "Remove all slideshow pictures",
            onPressed: () => wallpaper.clearSlideshow(),
          ),
        ],

        const YamaSectionHeader("Effects"),
        YamaDropdown<int>(
          label: "Blur",
          icon: Icons.blur_on,
          value: s.wallpaperBlur,
          items: {for (final v in const [0, 2, 4, 8, 12, 16, 24]) v: v == 0 ? "Off" : "$v"},
          onChanged: s.setWallpaperBlur,
        ),
        YamaDropdown<int>(
          label: "Dim",
          icon: Icons.brightness_6_outlined,
          value: s.wallpaperDim,
          items: {for (final v in const [0, 10, 20, 30, 40, 50, 60, 70, 80]) v: percentLabel(v)},
          onChanged: s.setWallpaperDim,
        ),
        YamaDropdown<int>(
          label: "Brightness",
          icon: Icons.wb_sunny_outlined,
          value: s.wallpaperBrightness,
          items: {for (final v in const [-40, -25, -10, 0, 10, 25, 40]) v: v == 0 ? "Normal" : (v > 0 ? "+$v" : "$v")},
          onChanged: (v) => s.setValue(YamaKeys.wallpaperBrightness, v),
        ),
        YamaDropdown<int>(
          label: "Color intensity",
          icon: Icons.invert_colors,
          value: s.wallpaperSaturation,
          items: const {0: "Black & white", 40: "Muted", 70: "Soft", 100: "Normal", 130: "Rich", 160: "Vivid"},
          onChanged: (v) => s.setValue(YamaKeys.wallpaperSaturation, v),
        ),
        YamaDropdown<int>(
          label: "Tint",
          icon: Icons.color_lens_outlined,
          value: s.wallpaperTintStrength,
          items: {for (final v in const [0, 10, 20, 30, 45, 60, 80]) v: percentLabel(v)},
          onChanged: (v) => s.setValue(YamaKeys.wallpaperTintStrength, v),
        ),
        if (s.wallpaperTintStrength > 0)
          YamaColorPicker(
            label: "Tint color",
            icon: Icons.colorize,
            value: s.wallpaperTintColor,
            onChanged: (v) => s.setValue(YamaKeys.wallpaperTintColor, v),
          ),
        YamaDropdown<int>(
          label: "Top & bottom shadow",
          icon: Icons.gradient_outlined,
          value: s.wallpaperShadow,
          items: {for (final v in const [0, 20, 35, 50, 65, 80]) v: percentLabel(v)},
          onChanged: (v) => s.setValue(YamaKeys.wallpaperShadow, v),
        ),
      ],
    );
  }

  static Future<void> _guard(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } on NoFileExplorerException {
      if (context.mounted) {
        _toast(context, AppLocalizations.of(context)!.dialogTextNoFileExplorer, error: true);
      }
    }
  }

  static void _toast(BuildContext context, String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            Icon(error ? Icons.error_outline : Icons.check_circle_outline,
                color: error ? Colors.redAccent : Colors.lightGreenAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
