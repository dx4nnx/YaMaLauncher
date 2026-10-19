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
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'flauncher.dart';

class FLauncherApp extends StatelessWidget
{
  static const PrioritizedIntents _backIntents = PrioritizedIntents(orderedIntents: [
    DismissIntent(),
    BackIntent()
  ]);

  static const MaterialColor _swatch = MaterialColor(0xFF011526, <int, Color>{
    50: Color(0xFF36A0FA),
    100: Color(0xFF067BDE),
    200: Color(0xFF045CA7),
    300: Color(0xFF033662),
    400: Color(0xFF022544),
    500: Color(0xFF011526),
    600: Color(0xFF000508),
    700: Color(0xFF000000),
    800: Color(0xFF000000),
    900: Color(0xFF000000),
  });

  const FLauncherApp();

  @override
  Widget build(BuildContext context) {
    AppsService appsService = context.read<AppsService>();
    LauncherState launcherState = context.read<LauncherState>();
    launcherState.refresh(appsService);

    return Consumer<SettingsService>(
      builder: (context, settings, _) => MaterialApp(
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.escape): _backIntents,
        const SingleActivator(LogicalKeyboardKey.gameButtonB): _backIntents,
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent()
      },
      actions: {
        ...WidgetsApp.defaultActions,
        BackIntent: BackAction(context),
        DirectionalFocusIntent: SoundFeedbackDirectionalFocusAction(context)
      },
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'YaMa Launcher',
      theme: _yamaTheme(settings),
      builder: (context, child) {
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear((settings.textScale / 100).clamp(0.7, 1.6).toDouble())),
          child: child!,
        );
      },
      home: Builder(
        builder: (context) => PopScope(
          canPop: false,
          child: FLauncher(),
          onPopInvoked: (didPop) {
            LauncherState launcherState = context.read<LauncherState>();
            launcherState.handleBackNavigation(context);
          }
        )
      ),
    ));
  }

  static ThemeData _yamaTheme(SettingsService settings) {
    final Color accent = Color(settings.accentColor);
    final String? family = settings.fontFamily == "System" ? null : settings.fontFamily;
    const Color surface = Color(0xFF151B2E);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(primary: accent, surface: surface);

    final TextTheme text = Typography.material2018().white.apply(fontFamily: family);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: family,
      textTheme: text,
      primaryColor: const Color(0xCC1A2238),
      primaryColorLight: accent.withOpacity(0.35),
      cardColor: const Color(0xFF243052),
      canvasColor: const Color(0xFF1C2540),
      dialogBackgroundColor: const Color(0xEE182036),
      scaffoldBackgroundColor: const Color(0xFF101626),
      focusColor: accent.withOpacity(0.28),
      hoverColor: accent.withOpacity(0.12),
      dividerColor: Colors.white.withOpacity(0.10),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.white70),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? accent.withOpacity(0.8) : Colors.white24),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xEE182036),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xEE1C2540),
        contentTextStyle: TextStyle(color: Colors.white, fontFamily: family),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(elevation: 0, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      typography: Typography.material2018(),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
        labelStyle: Typography.material2018().white.bodyMedium,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: accent.withOpacity(0.4),
        selectionHandleColor: accent,
      ),
    );
  }
}
