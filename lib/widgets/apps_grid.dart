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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/category.dart';
import '../models/layout_options.dart';
import '../models/yama_settings.dart';
import '../providers/settings_service.dart';
import 'category_container_common.dart';

class AppsGrid extends StatelessWidget
{
  final Category category;
  final List<App> applications;

  AppsGrid({
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
      final look = context.select<SettingsService, ({CardShape shape, bool label, double glow, double gap, int across})>(
        (s) => (
          shape: s.cardShape,
          label: s.labelMode != LabelMode.never,
          glow: s.focusEffect == FocusEffect.glow ? s.glowSize.toDouble() : 0.0,
          gap: s.cardSpacing.toDouble(),
          across: s.cardsAcross,
        ),
      );
      categoryContent = LayoutBuilder(
        builder: (context, constraints) => GridView.custom(
        primary: false,
        shrinkWrap: true,
        gridDelegate: _buildSliverGridDelegate(look, constraints.maxWidth),
        padding: EdgeInsets.all(16.0 + look.glow),
        childrenDelegate: SliverChildBuilderDelegate(
          childCount: applications.length,
          findChildIndexCallback: _findChildIndex,
          (context, index) => AppCard(
              key: Key(applications[index].packageName),
              category: category,
              application: applications[index],
              autofocus: index == 0,
              onMove: (direction) => _onMove(context, direction, index),
              onMoveEnd: () => _saveOrder(context)
          )
        )
      ));
    }

    return yamaCategoryShell(context, category.name, categoryContent);
  }

  int _findChildIndex(Key key) =>
      applications.indexWhere((app) => app.packageName == (key as ValueKey<String>).value);

  void _onMove(BuildContext context, AxisDirection direction, int index) {
    final int columnsCount = _columns(context.read<SettingsService>().cardsAcross);
    final currentRow = (index / columnsCount).floor();
    final totalRows = ((applications.length - 1) / columnsCount).floor();

    int? newIndex;
    switch (direction) {
      case AxisDirection.up:
        if (currentRow > 0) {
          newIndex = index - columnsCount;
        }
        break;
      case AxisDirection.right:
        if (index < applications.length - 1) {
          newIndex = index + 1;
        }
        break;
      case AxisDirection.down:
        if (currentRow < totalRows) {
          newIndex = min(index + columnsCount, applications.length - 1);
        }
        break;
      case AxisDirection.left:
        if (index > 0) {
          newIndex = index - 1;
        }
        break;
    }
    if (newIndex != null) {
      final appsService = context.read<AppsService>();
      appsService.reorderApplication(category, index, newIndex);
    }
  }

  void _saveOrder(BuildContext context) {
    final appsService = context.read<AppsService>();
    appsService.saveApplicationOrderInCategory(category);
  }

  int _columns(int across) => across > 0 ? across : category.columnsCount;

  SliverGridDelegate _buildSliverGridDelegate(
      ({CardShape shape, bool label, double glow, double gap, int across}) look, double availableWidth) {
    final int columns = _columns(look.across);
    final double padding = 16.0 + look.glow;
    final double cellWidth = max(1.0, (availableWidth - padding * 2 - look.gap * (columns - 1)) / columns);
    final double labelHeight = look.label ? appLabelHeight : 0;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisExtent: cellWidth / cardAspectRatio(look.shape) + labelHeight,
      mainAxisSpacing: max(look.gap, 16.0 + look.glow),
      crossAxisSpacing: look.gap,
    );
  }

}
