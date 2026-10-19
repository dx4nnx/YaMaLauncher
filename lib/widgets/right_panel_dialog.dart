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

import 'dart:ui' show ImageFilter;

import 'package:flauncher/actions.dart';
import 'package:flutter/material.dart';

class RightPanelDialog extends StatelessWidget {
  final Widget child;
  final double width;

  const RightPanelDialog({
    required this.child,
    this.width = 250,
  });

  @override
  Widget build(BuildContext context) {
    const BorderRadius radius = BorderRadius.horizontal(left: Radius.circular(32));

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.only(left: MediaQuery.of(context).size.width - width),
      shape: const RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A2238).withOpacity(0.78),
                const Color(0xFF101626).withOpacity(0.86),
              ],
            ),
            border: Border(left: BorderSide(color: Colors.white.withOpacity(0.14))),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Actions(actions: { BackIntent: BackAction(context) }, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
