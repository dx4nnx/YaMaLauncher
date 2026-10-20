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

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/widgets/settings/yama_controls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sending the Fire TV Home button to YaMa (via the accessibility helper).
class HomeButtonPanelPage extends StatefulWidget {
  static const String routeName = "home_button_panel";

  @override
  State<HomeButtonPanelPage> createState() => _HomeButtonPanelPageState();
}

class _HomeButtonPanelPageState extends State<HomeButtonPanelPage> {
  ({bool serviceOn, bool enabled})? _status;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await context.read<FLauncherChannel>().homeButtonStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) setState(() => _status = (serviceOn: false, enabled: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final FLauncherChannel channel = context.read<FLauncherChannel>();
    final ({bool serviceOn, bool enabled})? status = _status;

    return YamaSettingsPage(
      title: "Home button",
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
          child: Row(
            children: [
              Icon(
                status?.serviceOn == true ? Icons.check_circle_outline : Icons.info_outline,
                color: status?.serviceOn == true ? Colors.lightGreenAccent : Colors.white70,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status == null
                      ? "Checking…"
                      : status.serviceOn
                          ? "The Home button helper is switched on."
                          : "The Home button helper isn't switched on yet. Use the ADB steps below once.",
                ),
              ),
            ],
          ),
        ),
        if (status != null)
          YamaSwitch(
            autofocus: true,
            label: "Home button opens YaMa",
            icon: Icons.home_outlined,
            value: status.enabled,
            onChanged: (value) async {
              await channel.setHomeButtonEnabled(value);
              await _refresh();
            },
          ),
        YamaNavButton(
          icon: Icons.usb,
          label: "Switch the helper on with ADB",
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text("Switch on the Home button helper"),
              content: SingleChildScrollView(
                child: SelectableText(
                  "Fire TV doesn't let you choose another home app, so YaMa uses a small accessibility helper: "
                  "when the Fire TV home screen opens, YaMa opens on top of it. It only watches for the Fire TV "
                  "home screen.\n\n"
                  "In the platform-tools folder on your PC, first check for other helpers already on:\n\n"
                  "adb shell settings get secure enabled_accessibility_services\n\n"
                  "If that prints null (nothing on), run:\n\n"
                  "adb shell settings put secure enabled_accessibility_services app.yama.launcher/me.efesser.flauncher.YamaHomeService\n"
                  "adb shell settings put secure accessibility_enabled 1\n\n"
                  "If it printed something, keep it and add YaMa after a colon, e.g.\n"
                  "adb shell settings put secure enabled_accessibility_services \"WHAT-IT-PRINTED:app.yama.launcher/me.efesser.flauncher.YamaHomeService\"\n\n"
                  "Then come back to this page. A Fire OS update may switch it off; just run the commands again.",
                ),
              ),
            ),
          ).then((_) => _refresh()),
        ),
        YamaNavButton(
          icon: Icons.refresh,
          label: "Check again",
          onPressed: _refresh,
        ),
        const YamaSectionHeader("Fire TV home screen"),
        YamaNavButton(
          icon: Icons.tv_outlined,
          label: "Open Fire TV home (stays for 1 minute)",
          onPressed: () => channel.openFireTvHome(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
          child: Text(
            "For Fire TV settings, the Appstore or profiles. After a minute, Home opens YaMa again.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
