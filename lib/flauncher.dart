/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
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


import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/idle_fader.dart';
import 'package:flauncher/widgets/launcher_alternative_view.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/yama_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'models/category.dart';

class FLauncher extends StatelessWidget {
  const FLauncher();

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    policy: RowByRowTraversalPolicy(),
    child: Stack(
      children: [
        const Positioned.fill(child: YamaBackground()),
        Consumer<LauncherState>(
          builder: (_, state, child) => Visibility(
            child: child!,
            replacement: const Center(
              child: AlternativeLauncherView()
            ),
            visible: state.launcherVisible
          ),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () =>
                  context.read<WallpaperService>().nextWallpaper(),
              const SingleActivator(LogicalKeyboardKey.mediaPlay): () =>
                  context.read<WallpaperService>().nextWallpaper(),
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: FocusAwareAppBar(),
              body: Consumer2<AppsService, SettingsService>(
                builder: (context, appsService, settings, _) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    settings.marginLeft.toDouble(),
                    16 + settings.marginTop.toDouble(),
                    settings.marginRight.toDouble(),
                    0
                  ),
                  child: appsService.initialized
                      ? IdleFader(
                          child: SingleChildScrollView(
                            child: _sections(appsService.launcherSections, settings)
                          )
                        )
                      : _emptyState(context)
                )
              )
            )
          )
        )
      ]
    )
  );

  Widget _sections(List<LauncherSection> sections, SettingsService settings) => Column(
    children: sections.where((section) =>
        !(settings.hideEmptyCategories && section is Category && section.applications.isEmpty)
    ).map((section) {
      final Key sectionKey = Key(section.id.toString());
      final Widget categoryWidget;

      if (section is LauncherSpacer) {
        return SizedBox(key: sectionKey, height: section.height.toDouble());
      }

      Category category = section as Category;
      switch (category.type) {
        case CategoryType.row:
          categoryWidget = CategoryRow(
              key: sectionKey,
              category: category,
              applications: category.applications
          );
        case CategoryType.grid:
          categoryWidget = AppsGrid(
              key: sectionKey,
              category: category,
              applications: category.applications
          );
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: settings.sectionSpacing / 2),
        child: categoryWidget
      );
    }).toList(),
  );

  Widget _emptyState(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(localizations.loading, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
