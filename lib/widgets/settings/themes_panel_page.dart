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

import 'dart:io';

import 'package:flauncher/models/yama_settings.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/yama_controls.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

const String yamaThemeFileName = "yama-theme.json";

/// Built-in looks, saving/loading a theme file, reset, and idle mode.
class ThemesPanelPage extends StatelessWidget {
  static const String routeName = "themes_panel";

  @override
  Widget build(BuildContext context) {
    final SettingsService s = context.watch<SettingsService>();

    return YamaSettingsPage(
      title: "Themes & idle",
      children: [
        const YamaSectionHeader("Your saved themes"),
        for (int slot = 0; slot < SettingsService.customThemeSlots; slot++) ...[
          if (s.hasCustomTheme(slot))
            YamaNavButton(
              autofocus: slot == 0,
              icon: Icons.palette,
              label: "Apply “${s.customThemeName(slot)}”",
              onPressed: () async {
                final bool ok = await s.applyCustomTheme(slot);
                if (context.mounted) _toast(context, ok ? "Applied “${s.customThemeName(slot)}”" : "That theme couldn't be loaded", error: !ok);
              },
            ),
          YamaNavButton(
            autofocus: slot == 0 && !s.hasCustomTheme(0),
            icon: s.hasCustomTheme(slot) ? Icons.save_as_outlined : Icons.add_circle_outline,
            label: s.hasCustomTheme(slot)
                ? "Replace “${s.customThemeName(slot)}” with current look"
                : "Save current look as theme ${slot + 1}",
            onPressed: () async {
              final String? name = await yamaTextDialog(
                context,
                title: "Name this theme",
                initial: s.hasCustomTheme(slot) ? s.customThemeName(slot) : "My theme ${slot + 1}",
              );
              if (name == null) return;
              await s.saveCustomTheme(slot, name);
              if (context.mounted) _toast(context, "Saved “${s.customThemeName(slot)}”");
            },
          ),
          if (s.hasCustomTheme(slot))
            YamaNavButton(
              icon: Icons.delete_outline,
              label: "Delete “${s.customThemeName(slot)}”",
              onPressed: () async {
                await s.deleteCustomTheme(slot);
              },
            ),
        ],

        const YamaSectionHeader("Built-in looks"),
        for (final entry in yamaPresets.entries)
          YamaNavButton(
            icon: Icons.style_outlined,
            label: entry.key,
            onPressed: () async {
              await s.applyAppearance(entry.value);
              if (context.mounted) {
                _toast(context, "Applied “${entry.key}”");
              }
            },
          ),

        const YamaSectionHeader("Your theme file"),
        YamaNavButton(
          icon: Icons.save_alt,
          label: "Save current look to file",
          onPressed: () async {
            final File? file = await _themeFile();
            if (file == null) {
              if (context.mounted) _toast(context, "Storage isn't available on this device", error: true);
              return;
            }
            await file.writeAsString(s.exportAppearance());
            if (context.mounted) _toast(context, "Saved to ${file.path}");
          },
        ),
        YamaNavButton(
          icon: Icons.file_open_outlined,
          label: "Load look from file",
          onPressed: () async {
            final File? file = await _themeFile();
            if (file == null || !await file.exists()) {
              if (context.mounted) {
                _toast(context, "No theme file found. Save one first, or copy one to ${file?.path ?? yamaThemeFileName}",
                    error: true);
              }
              return;
            }
            bool loaded = false;
            try {
              loaded = await s.importAppearance(await file.readAsString());
            } on FormatException {
              loaded = false;
            }
            if (context.mounted) {
              _toast(context, loaded ? "Theme loaded" : "That file isn't a YaMa theme", error: !loaded);
            }
          },
        ),
        YamaNavButton(
          icon: Icons.restart_alt,
          label: "Reset look to YaMa defaults",
          onPressed: () async {
            await s.resetAppearance();
            if (context.mounted) _toast(context, "Look reset");
          },
        ),

        const YamaSectionHeader("Idle mode"),
        YamaDropdown<int>(
          label: "Fade apps after",
          icon: Icons.bedtime_outlined,
          value: s.idleTimeout,
          items: const {
            0: "Never", 30: "30 seconds", 60: "1 minute", 120: "2 minutes",
            300: "5 minutes", 600: "10 minutes", 1800: "30 minutes",
          },
          onChanged: (v) => s.setValue(YamaKeys.idleTimeout, v),
        ),
        if (s.idleTimeout > 0)
          YamaDropdown<int>(
            label: "How much stays visible",
            icon: Icons.opacity,
            value: s.idleOpacity,
            items: const {0: "Nothing (wallpaper & clock only)", 10: "10%", 25: "25%", 40: "40%", 60: "60%"},
            onChanged: (v) => s.setValue(YamaKeys.idleOpacity, v),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Text(
            "Any button wakes the launcher. The first press only wakes it, so nothing opens by accident.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  /// The theme file lives in this app's own storage folder
  /// (Android/data/<app>/files), which ADB and file managers can reach.
  static Future<File?> _themeFile() async {
    Directory? directory;
    try {
      directory = await getExternalStorageDirectory();
    } catch (_) {
      directory = null;
    }
    directory ??= await getApplicationDocumentsDirectory();
    return File("${directory.path}/$yamaThemeFileName");
  }

  static void _toast(BuildContext context, String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 7),
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
