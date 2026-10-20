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
import 'package:flauncher/widgets/yama_file_browser.dart';
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
            WallpaperMode.reddit: "Reddit wallpapers",
            WallpaperMode.web: "Web image links",
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
          onPressed: () async {
            final String? path = await showYamaFileBrowser(context, title: "Choose a wallpaper");
            if (path != null) await wallpaper.setWallpaperFromFile(path);
          },
        ),
        YamaNavButton(
          icon: Icons.drive_folder_upload_outlined,
          label: "Add a folder to the slideshow",
          onPressed: () async {
            final String? folder = await showYamaFileBrowser(context, title: "Choose a folder of pictures", mode: BrowseMode.folder);
            if (folder == null) return;
            final int added = await wallpaper.addSlideshowFolder(folder);
            if (context.mounted) {
              _toast(context, "Added $added picture${added == 1 ? "" : "s"} to the slideshow");
            }
          },
        ),
        YamaNavButton(
          icon: Icons.collections_outlined,
          label: "Add pictures with another app",
          onPressed: () => _guard(context, () async {
            final int added = await wallpaper.addSlideshowPictures();
            if (added > 0 && context.mounted) {
              _toast(context, "Added $added picture${added == 1 ? "" : "s"} to the slideshow");
            }
          }),
        ),
        if (wallpaper.deviceFolderPath != null)
          YamaNavButton(
            icon: Icons.usb,
            label: "Copy pictures to the TV with ADB",
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Copy pictures with ADB"),
                content: SelectableText(
                  "On your PC, in the platform-tools folder, run:\n\n"
                  "adb push \"C:\\path\\to\\your\\pictures\\.\" ${wallpaper.deviceFolderPath}/\n\n"
                  "Then choose \"Reload slideshow pictures\". The pictures join the slideshow "
                  "(Wallpaper → Show → Slideshow). This works well with the androidtvbackground "
                  "TMDB script: push its output folder after each run.",
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")),
                ],
              ),
            ),
          ),
        YamaNavButton(
          icon: Icons.refresh,
          label: "Reload slideshow pictures",
          onPressed: () async {
            await wallpaper.reloadSlides();
            if (context.mounted) {
              _toast(context, "${wallpaper.slideCount} slideshow picture${wallpaper.slideCount == 1 ? "" : "s"} found");
            }
          },
        ),
        if (s.wallpaperMode == WallpaperMode.solid)
          YamaColorPicker(
            label: "Solid color",
            icon: Icons.format_paint_outlined,
            value: s.wallpaperSolidColor,
            onChanged: (v) => wallpaper.setSolidColor(Color(v)),
          ),

        if (s.wallpaperMode == WallpaperMode.reddit) ...[
          const YamaSectionHeader("Reddit"),
          YamaNavButton(
            icon: Icons.forum_outlined,
            label: "Subreddits: ${s.redditSubreddits.isEmpty ? "none" : s.redditSubreddits}",
            onPressed: () async {
              final String? value = await yamaTextDialog(
                context,
                title: "Subreddits",
                initial: s.redditSubreddits,
                hint: "wallpaper, WidescreenWallpaper",
                help: "Names separated by commas, without r/. YaMa reads each subreddit's public feed "
                    "and uses picture posts; tall (phone-shaped) pictures are skipped.",
              );
              if (value != null) {
                await s.setValue(YamaKeys.redditSubreddits, value.trim());
              }
            },
          ),
          for (final suggestion in yamaSuggestedSubreddits.entries)
            if (!_hasSubreddit(s.redditSubreddits, suggestion.key))
              YamaNavButton(
                icon: Icons.add,
                label: "Add r/${suggestion.key} (${suggestion.value})",
                onPressed: () => s.setValue(
                  YamaKeys.redditSubreddits,
                  s.redditSubreddits.trim().isEmpty ? suggestion.key : "${s.redditSubreddits.trim()}, ${suggestion.key}",
                ),
              ),
          _remoteStatus(context, wallpaper, "Reddit"),
        ],
        if (s.wallpaperMode == WallpaperMode.web) ...[
          const YamaSectionHeader("Web image links"),
          YamaNavButton(
            icon: Icons.link,
            label: s.webImageUrls.isEmpty ? "Add image links" : "Image links (${s.webImageUrls.split(RegExp(r"[\s,;]+")).where((p) => p.isNotEmpty).length})",
            onPressed: () async {
              final String? value = await yamaTextDialog(
                context,
                title: "Image links",
                initial: s.webImageUrls,
                hint: "https://example.com/wallpaper.jpg",
                help: "Links to pictures, or to a folder (ending in /) that lists pictures, separated by spaces. "
                    "For the androidtvbackground TMDB script: on the PC, open its output folder and run "
                    "python -m http.server 8000, then enter http://YOUR-PC-IP:8000/ here. "
                    "Folders are re-read every hour, so new pictures show up.",
              );
              if (value != null) {
                await s.setValue(YamaKeys.webImageUrls, value.trim());
              }
            },
          ),
          _remoteStatus(context, wallpaper, "the links"),
        ],

        if (wallpaper.slideCount > 0 ||
            s.wallpaperMode == WallpaperMode.reddit ||
            s.wallpaperMode == WallpaperMode.web) ...[
          const YamaSectionHeader("Changing pictures"),
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
          if (wallpaper.slideCount > 0)
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

  static bool _hasSubreddit(String list, String name) => list
      .split(RegExp(r"[\s,;]+"))
      .any((part) => part.replaceFirst(RegExp(r"^/?r/", caseSensitive: false), "").toLowerCase() == name.toLowerCase());

  static Widget _remoteStatus(BuildContext context, WallpaperService wallpaper, String sourceName) {
    final String text;
    final IconData icon;
    if (wallpaper.remoteLoading) {
      text = "Loading pictures from $sourceName…";
      icon = Icons.downloading;
    } else if (wallpaper.remoteError != null) {
      text = wallpaper.remoteError!;
      icon = Icons.error_outline;
    } else {
      text = "${wallpaper.remoteCount} picture${wallpaper.remoteCount == 1 ? "" : "s"} ready";
      icon = Icons.check_circle_outline;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: wallpaper.remoteError != null ? Colors.redAccent : Colors.white70),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ),
        YamaNavButton(
          icon: Icons.refresh,
          label: "Reload pictures",
          onPressed: wallpaper.reloadRemote,
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
