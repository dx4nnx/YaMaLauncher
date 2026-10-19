import 'dart:ui' show ImageFilter;

import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'ensure_visible.dart';

Widget categoryContainerEmptyState(BuildContext context) {
  AppLocalizations localizations = AppLocalizations.of(context)!;

  return SizedBox(
    height: 110,
    child: EnsureVisible(
      // This specific alignment value is not only
      // to center the focused card in the row while
      // scrolling, but to prevent the topmost category
      // title to be hidden by the content above it when
      // scrolling from the app bar. How it relates to this,
      // I don't know
      alignment: 0.5,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => SettingsPanel(initialRoute: LauncherSectionsPanelPage.routeName),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      localizations.textEmptyCategory,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Category title plus content, optionally inside YaMa's soft glass "dock".
Widget yamaCategoryShell(BuildContext context, String title, Widget content) {
  final shell = context.select<SettingsService, ({bool titles, bool dock, int opacity, bool blur})>(
    (s) => (titles: s.showCategoryTitles, dock: s.dockEnabled, opacity: s.dockOpacity, blur: s.dockBlur),
  );

  final Widget column = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (shell.titles)
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.white.withOpacity(0.92),
              shadows: [const Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 8)],
            ),
          ),
        ),
      content,
    ],
  );

  if (!shell.dock) {
    return column;
  }

  final BorderRadius radius = BorderRadius.circular(28);
  final Widget panel = Container(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    decoration: BoxDecoration(
      borderRadius: radius,
      color: Colors.white.withOpacity((shell.opacity / 100).clamp(0.0, 0.8).toDouble()),
      border: Border.all(color: Colors.white.withOpacity(0.10)),
    ),
    child: column,
  );

  if (!shell.blur) {
    return panel;
  }

  return ClipRRect(
    borderRadius: radius,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: panel,
    ),
  );
}
