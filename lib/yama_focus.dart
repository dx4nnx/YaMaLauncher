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

import 'package:flutter/material.dart';

/// Solid fill behind whatever is selected with the remote: a deep, saturated
/// version of the accent color, so white text stays readable on it.
Color yamaFocusFill(Color accent) {
  final HSLColor hsl = HSLColor.fromColor(accent);
  return hsl.withSaturation(hsl.saturation < 0.55 ? 0.65 : hsl.saturation).withLightness(0.40).toColor();
}

/// Outline drawn around whatever is selected.
const Color yamaFocusOutline = Colors.white;
const double yamaFocusOutlineWidth = 3;
