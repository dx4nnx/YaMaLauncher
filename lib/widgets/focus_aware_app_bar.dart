import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_service.dart';

/// Taller than Material's default so a big or two-line clock fits.
const double yamaBarHeight = 80;
import 'date_time_widget.dart';
import 'network_widget.dart';

class FocusAwareAppBar extends StatefulWidget implements PreferredSizeWidget
{
  @override
  State<StatefulWidget> createState() {
    return _FocusAwareAppBarState();
  }

  @override
  Size get preferredSize => const Size.fromHeight(yamaBarHeight);
}

class _FocusAwareAppBarState extends State<FocusAwareAppBar>
{
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsService, bool>(
      selector: (_, settings) => settings.autoHideAppBarEnabled,
      builder: (context, autoHide, widget) {
        if (autoHide) {
          return Focus(
            canRequestFocus: false,
            child: AnimatedContainer(
              curve: Curves.decelerate,
              duration: Duration(milliseconds: 250),
              height: focused ? yamaBarHeight : 0,
              child: widget!
            ),
            onFocusChange: (hasFocus) {
              this.setState(() {
                focused = hasFocus;
              });
            }
          );
        }

        return widget!;
      },
      child: AppBar(
        toolbarHeight: yamaBarHeight,
        actions: [
          IconButton(
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(),
            splashRadius: 20,
            icon: const Icon(Icons.settings_outlined,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            onPressed: () => showDialog(context: context, builder: (_) => const SettingsPanel()),
            // sometime after Flutter 3.7.5, no later than 3.16.8, the focus highlight went away
            focusColor: Theme.of(context).primaryColorLight,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: NetworkWidget(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 32),
            child: Consumer<SettingsService>(
              builder: (context, settings, _) => ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: yamaBarHeight - 8),
                child: FittedBox(fit: BoxFit.scaleDown, child: _clock(context, settings)),
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget _clock(BuildContext context, SettingsService settings) {
    final double size = settings.clockSize.toDouble();
    final Color color = Color(settings.clockColor);
    final List<Shadow> shadows = settings.clockShadow
        ? const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 10)]
        : const [];

    final TextStyle timeStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w700,
      height: 1.05,
      shadows: shadows,
    );
    final TextStyle dateStyle = timeStyle.copyWith(
      fontSize: settings.clockTwoLines ? size * 0.5 : size * 0.8,
      fontWeight: FontWeight.w400,
      color: color.withOpacity(0.85),
    );

    final bool showDate = settings.showDateInStatusBar;
    final bool showTime = settings.showTimeInStatusBar;

    if (settings.clockTwoLines) {
      return Column(
        key: ValueKey("clock-2-${settings.dateFormat}-${settings.timeFormat}"),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showTime) DateTimeWidget(settings.timeFormat, key: ValueKey("t-${settings.timeFormat}"), textStyle: timeStyle),
          if (showDate)
            DateTimeWidget(settings.dateFormat,
              key: ValueKey("d-${settings.dateFormat}"),
              updateInterval: const Duration(minutes: 1),
              textStyle: dateStyle,
            ),
        ],
      );
    }

    return Row(
      key: ValueKey("clock-1-${settings.dateFormat}-${settings.timeFormat}"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // No Flexible here: the clock sits in a FittedBox (unbounded width).
        if (showDate)
          DateTimeWidget(settings.dateFormat,
            key: ValueKey("d-${settings.dateFormat}"),
            updateInterval: const Duration(minutes: 1),
            textStyle: dateStyle,
          ),
        if (showDate && showTime) const SizedBox(width: 14),
        if (showTime)
          DateTimeWidget(settings.timeFormat, key: ValueKey("t-${settings.timeFormat}"), textStyle: timeStyle),
      ],
    );
  }
}
