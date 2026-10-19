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

import 'dart:math';

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/category_container_common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/category.dart';
import '../models/layout_options.dart';
import '../models/yama_settings.dart';
import '../providers/settings_service.dart';

class CategoryRow extends StatelessWidget
{
  final Category category;
  final List<App> applications;

  CategoryRow({
    Key? key,
    required this.category,
    required this.applications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget categoryContent;
    if (applications.isEmpty) {
      categoryContent = categoryContainerEmptyState(context);
    }
    else {
      final look = context.select<SettingsService, ({
        CardShape shape, bool label, double zoom, double glow, double gap, int across
      })>((s) => (
        shape: s.cardShape,
        label: s.labelMode != LabelMode.never,
        zoom: s.focusZoom,
        glow: s.focusEffect == FocusEffect.glow ? s.glowSize.toDouble() : 0.0,
        gap: s.cardSpacing.toDouble(),
        across: s.cardsAcross,
      ));

      categoryContent = LayoutBuilder(
        builder: (context, constraints) {
          final double ratio = cardAspectRatio(look.shape);
          final double labelHeight = look.label ? appLabelHeight : 0;

          // Card size: either from the category's row height, or chosen so
          // exactly "apps across the screen" cards fit the width.
          double cardWidth;
          double cardHeight;
          if (look.across > 0 && constraints.maxWidth.isFinite) {
            final int n = look.across;
            cardWidth = (constraints.maxWidth - 2 * look.glow - 16 - look.gap * (n - 1)) / (n + look.zoom - 1);
            cardWidth = max(40.0, cardWidth);
            cardHeight = cardWidth / ratio;
          } else {
            cardHeight = (category.rowHeight - 16).toDouble();
            cardWidth = cardHeight * ratio;
          }

          final double verticalPadding = max(8.0, cardHeight * (look.zoom - 1) / 2 + 4 + look.glow);
          final double horizontalPadding = max(8.0, cardWidth * (look.zoom - 1) / 2 + look.glow);

          return SizedBox(
            height: cardHeight + labelHeight + verticalPadding * 2,
            child: ListView.custom(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              scrollDirection: Axis.horizontal,
              childrenDelegate: SliverChildBuilderDelegate(
                childCount: applications.length,
                findChildIndexCallback: _findChildIndex,
                (context, index) => Padding(
                  key: Key(applications[index].packageName),
                  padding: EdgeInsets.symmetric(horizontal: look.gap / 2),
                  child: SizedBox(
                    width: cardWidth,
                    child: AppCard(
                      category: category,
                      application: applications[index],
                      autofocus: index == 0,
                      onMove: (direction) => _onMove(context, direction, index),
                      onMoveEnd: () => _onMoveEnd(context)
                    )
                  )
                )
              )
            )
          );
        }
      );
    }

    return yamaCategoryShell(context, category.name, categoryContent);
  }

  int _findChildIndex(Key key) =>
      applications.indexWhere((app) => app.packageName == (key as ValueKey<String>).value);

  void _onMove(BuildContext context, AxisDirection direction, int index) {
    int newIndex = 0;

    if (direction == AxisDirection.right && index < applications.length - 1) {
      newIndex = index + 1;
    } else if (direction == AxisDirection.left && index > 0) {
      newIndex = index - 1;
    } else {
      return;
    }

    final appsService = context.read<AppsService>();
    appsService.reorderApplication(category, index, newIndex);
  }

  void _onMoveEnd(BuildContext context) {
    final appsService = context.read<AppsService>();
    appsService.saveApplicationOrderInCategory(category);
  }
}
