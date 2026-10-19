/*
 * FLauncher
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

/// Shape of the app cards shown on the home screen.
enum CardShape
{
  /// Wide 16:9 card showing the app's TV banner (original FLauncher look).
  banner,

  /// Square card showing the app icon.
  square,

  /// Round card showing the app icon.
  circle,
}

/// When the app name is shown underneath a card.
enum LabelMode
{
  never,
  focused,
  always,
}

/// Height reserved under each card for its name, when names are enabled.
const double appLabelHeight = 26;

double cardAspectRatio(CardShape shape) => shape == CardShape.banner ? 16 / 9 : 1.0;

CardShape cardShapeFromName(String? name) =>
    CardShape.values.firstWhere((value) => value.name == name, orElse: () => CardShape.banner);

LabelMode labelModeFromName(String? name) =>
    LabelMode.values.firstWhere((value) => value.name == name, orElse: () => LabelMode.never);
