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

import 'dart:async';

import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Fades [child] out after the home screen has been left alone for the
/// configured time, leaving the wallpaper and clock. The first key press
/// while faded only wakes the launcher, so nothing gets launched by accident.
class IdleFader extends StatefulWidget {
  final Widget child;

  const IdleFader({super.key, required this.child});

  @override
  State<IdleFader> createState() => _IdleFaderState();
}

class _IdleFaderState extends State<IdleFader> with WidgetsBindingObserver {
  Timer? _timer;
  bool _idle = false;
  int _timeout = 0;
  final Set<PhysicalKeyboardKey> _swallowed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _wake();
    }
    else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  bool _onKey(KeyEvent event) {
    if (_swallowed.contains(event.physicalKey)) {
      if (event is KeyUpEvent) {
        _swallowed.remove(event.physicalKey);
      }
      return true;
    }

    if (_idle && event is KeyDownEvent) {
      _swallowed.add(event.physicalKey);
      _wake();
      return true;
    }

    _restartTimer();
    return false;
  }

  void _wake() {
    if (_idle && mounted) {
      setState(() => _idle = false);
    }
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_timeout > 0) {
      _timer = Timer(Duration(seconds: _timeout), () {
        if (mounted) {
          setState(() => _idle = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsService settings = context.watch<SettingsService>();
    if (settings.idleTimeout != _timeout) {
      _timeout = settings.idleTimeout;
      if (_timeout == 0) {
        _idle = false;
      }
      _restartTimer();
    }

    return AnimatedOpacity(
      duration: Duration(milliseconds: _idle ? 1500 : 250),
      curve: Curves.easeInOut,
      opacity: _idle ? (settings.idleOpacity / 100).clamp(0.0, 1.0).toDouble() : 1.0,
      child: widget.child,
    );
  }
}
