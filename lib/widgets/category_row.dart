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
      final SettingsService settings = context.watch<SettingsService>();
      final CardShape shape = settings.cardShape;
      final double cardHeight = (category.rowHeight - 16).toDouble();
      final double cardWidth = cardHeight * cardAspectRatio(shape);
      final double labelHeight = settings.labelMode == LabelMode.never ? 0 : appLabelHeight;
      final double zoomOverflow = cardHeight * (settings.focusZoom - 1) / 2;
      final double glowSpace = settings.focusEffect == FocusEffect.glow ? settings.glowSize.toDouble() : 0;
      final double verticalPadding = max(8.0, zoomOverflow + 4 + glowSpace);
      final double horizontalPadding = max(8.0, cardWidth * (settings.focusZoom - 1) / 2 + glowSpace);
      final double gap = settings.cardSpacing.toDouble();

      categoryContent = SizedBox(
        height: cardHeight + labelHeight + verticalPadding * 2,
        child: ListView.custom(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          scrollDirection: Axis.horizontal,
          childrenDelegate: SliverChildBuilderDelegate(
            childCount: applications.length,
            findChildIndexCallback: _findChildIndex,
            (context, index) => Padding(
                key: Key(applications[index].packageName),
                padding: EdgeInsets.symmetric(horizontal: gap / 2),
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
