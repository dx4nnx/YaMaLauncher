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
      // Solid panel, no live blur: blurring what's behind costs a lot on TV chips.
      child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF21A2238), Color(0xF7101626)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Actions(actions: { BackIntent: BackAction(context) }, child: child),
            ),
          ),
      ),
    );
  }
}
