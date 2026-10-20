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

import 'dart:async';

import 'dart:convert';

import 'package:flauncher/models/layout_options.dart';
import 'package:flauncher/models/yama_settings.dart';
import 'package:flauncher/widgets/settings/back_button_actions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _appHighlightAnimationEnabledKey = "app_highlight_animation_enabled";
const _appKeyClickEnabledKey = "app_key_click_enabled";
const _autoHideAppBar = "auto_hide_app_bar";
const _gradientUuidKey = "gradient_uuid";
const _backButtonAction = "back_button_action";
const _dateFormat = "date_format";
const _showCategoryTitles = "show_category_titles";
const _showDateInStatusBar = "show_date_in_status_bar";
const _showTimeInStatusBar = "show_time_in_status_bar";
const _timeFormat = "time_format";

class SettingsService extends ChangeNotifier {
  static final defaultDateFormat = "EEEE d";
  static final defaultTimeFormat = "H:mm";
  final SharedPreferences _sharedPreferences;


  bool get appHighlightAnimationEnabled => _sharedPreferences.getBool(_appHighlightAnimationEnabledKey) ?? true;

  bool get appKeyClickEnabled => _sharedPreferences.getBool(_appKeyClickEnabledKey) ?? true;

  bool get autoHideAppBarEnabled => _sharedPreferences.getBool(_autoHideAppBar) ?? false;

  bool get showCategoryTitles => _sharedPreferences.getBool(_showCategoryTitles) ?? true;

  bool get showDateInStatusBar => _sharedPreferences.getBool(_showDateInStatusBar) ?? true;

  bool get showTimeInStatusBar => _sharedPreferences.getBool(_showTimeInStatusBar) ?? true;

  String? get gradientUuid => _sharedPreferences.getString(_gradientUuidKey);

  String get backButtonAction => _sharedPreferences.getString(_backButtonAction) ?? BACK_BUTTON_ACTION_NOTHING;

  String get dateFormat => _sharedPreferences.getString(_dateFormat) ?? defaultDateFormat;

  String get timeFormat => _sharedPreferences.getString(_timeFormat) ?? defaultTimeFormat;

  // ---- YaMa appearance settings -------------------------------------------

  Object _value(String key) {
    final Object fallback = appearanceDefaults[key]!;
    final Object? stored = _sharedPreferences.get(key);
    if (stored == null || stored.runtimeType != fallback.runtimeType) {
      return fallback;
    }
    return stored;
  }

  int _int(String key) => _value(key) as int;
  bool _bool(String key) => _value(key) as bool;
  String _string(String key) => _value(key) as String;
  double _double(String key) => _value(key) as double;

  CardShape get cardShape => cardShapeFromName(_string(YamaKeys.cardShape));
  LabelMode get labelMode => labelModeFromName(_string(YamaKeys.labelMode));
  double get focusZoom => _double(YamaKeys.focusZoom);
  int get cornerRadius => _int(YamaKeys.cornerRadius);
  int get cardSpacing => _int(YamaKeys.cardSpacing);
  int get sectionSpacing => _int(YamaKeys.sectionSpacing);
  int get marginLeft => _int(YamaKeys.marginLeft);
  int get marginRight => _int(YamaKeys.marginRight);
  int get marginTop => _int(YamaKeys.marginTop);
  int get marginBottom => _int(YamaKeys.marginBottom);
  bool get dockEnabled => _bool(YamaKeys.dockEnabled);
  int get dockOpacity => _int(YamaKeys.dockOpacity);
  bool get dockBlur => _bool(YamaKeys.dockBlur);
  bool get hideEmptyCategories => _bool(YamaKeys.hideEmptyCategories);
  int get iconCardColor => _int(YamaKeys.iconCardColor);

  FocusEffect get focusEffect => enumFromName(FocusEffect.values, _string(YamaKeys.focusEffect), FocusEffect.glow);
  int get glowColor => _int(YamaKeys.glowColor);
  int get glowSize => _int(YamaKeys.glowSize);
  GlowAnimation get glowAnimation =>
      enumFromName(GlowAnimation.values, _string(YamaKeys.glowAnimation), GlowAnimation.breathe);
  int get focusTintColor => _int(YamaKeys.focusTintColor);
  int get focusTintStrength => _int(YamaKeys.focusTintStrength);
  int get unfocusedDim => _int(YamaKeys.unfocusedDim);

  WallpaperMode get wallpaperMode =>
      enumFromName(WallpaperMode.values, _string(YamaKeys.wallpaperMode), WallpaperMode.gradient);
  int get wallpaperSolidColor => _int(YamaKeys.wallpaperSolidColor);
  int get wallpaperDim => _int(YamaKeys.wallpaperDim);
  int get wallpaperBlur => _int(YamaKeys.wallpaperBlur);
  int get wallpaperTintColor => _int(YamaKeys.wallpaperTintColor);
  int get wallpaperTintStrength => _int(YamaKeys.wallpaperTintStrength);
  int get wallpaperBrightness => _int(YamaKeys.wallpaperBrightness);
  int get wallpaperSaturation => _int(YamaKeys.wallpaperSaturation);
  int get wallpaperShadow => _int(YamaKeys.wallpaperShadow);
  int get slideshowInterval => _int(YamaKeys.slideshowInterval);
  SlideEffect get slideshowTransition =>
      enumFromName(SlideEffect.values, _string(YamaKeys.slideshowTransition), SlideEffect.fade);

  int get clockColor => _int(YamaKeys.clockColor);
  int get clockSize => _int(YamaKeys.clockSize);
  bool get clockShadow => _bool(YamaKeys.clockShadow);
  bool get clockTwoLines => _bool(YamaKeys.clockTwoLines);
  String get fontFamily => _string(YamaKeys.fontFamily);
  int get textScale => _int(YamaKeys.textScale);
  int get accentColor => _int(YamaKeys.accentColor);

  /// Faster on slow TVs: no glow, shadows or slide animations.
  bool get smoothMode => _bool(YamaKeys.smoothMode);
  int get cardsAcross => _int(YamaKeys.cardsAcross);
  /// Rows a grid shows at once (0 = all); the rest scroll inside it.
  int get maxVisibleRows => _int(YamaKeys.maxVisibleRows);
  AppsPosition get appsPosition =>
      enumFromName(AppsPosition.values, _string(YamaKeys.appsPosition), AppsPosition.top);
  String get redditSubreddits => _string(YamaKeys.redditSubreddits);
  String get webImageUrls => _string(YamaKeys.webImageUrls);

  /// "wallpaper" = same pictures as the home screen, "own" = its own list.
  bool get screensaverOwnPictures => _string(YamaKeys.screensaverSource) == "own";
  /// Seconds per picture in the screensaver (0 = same as the wallpaper).
  int get screensaverInterval => _int(YamaKeys.screensaverInterval);
  int get idleTimeout => _int(YamaKeys.idleTimeout);
  int get idleOpacity => _int(YamaKeys.idleOpacity);

  /// Stores one appearance setting. [value] must have the same type as its
  /// default in [appearanceDefaults]; enums are stored by name.
  Future<void> setValue(String key, Object value) async {
    await _write(key, value is Enum ? value.name : value);
    notifyListeners();
  }

  Future<void> _write(String key, Object value) async {
    final Object? fallback = appearanceDefaults[key];
    if (fallback == null) {
      return;
    }
    if (fallback is bool && value is bool) {
      await _sharedPreferences.setBool(key, value);
    } else if (fallback is int && value is num) {
      await _sharedPreferences.setInt(key, value.round());
    } else if (fallback is double && value is num) {
      await _sharedPreferences.setDouble(key, value.toDouble());
    } else if (fallback is String && value is String) {
      await _sharedPreferences.setString(key, value);
    }
  }

  /// Applies many appearance settings at once (presets and imported themes).
  Future<void> applyAppearance(Map<String, Object?> values) async {
    for (final entry in values.entries) {
      if (entry.value != null) {
        await _write(entry.key, entry.value!);
      }
    }
    notifyListeners();
  }

  Future<void> resetAppearance() async {
    for (final key in appearanceDefaults.keys) {
      await _sharedPreferences.remove(key);
    }
    notifyListeners();
  }

  // ---- Your own saved themes ----------------------------------------------

  static const int customThemeSlots = 3;

  bool hasCustomTheme(int slot) => _sharedPreferences.containsKey("yama_custom_theme_$slot");

  String customThemeName(int slot) =>
      _sharedPreferences.getString("yama_custom_theme_name_$slot") ?? "My theme ${slot + 1}";

  Future<void> saveCustomTheme(int slot, String name) async {
    await _sharedPreferences.setString("yama_custom_theme_$slot", exportAppearance());
    await _sharedPreferences.setString("yama_custom_theme_name_$slot", name.trim().isEmpty ? "My theme ${slot + 1}" : name.trim());
    notifyListeners();
  }

  Future<bool> applyCustomTheme(int slot) async {
    final String? json = _sharedPreferences.getString("yama_custom_theme_$slot");
    if (json == null) {
      return false;
    }
    try {
      return await importAppearance(json);
    } on FormatException {
      return false;
    }
  }

  Future<void> deleteCustomTheme(int slot) async {
    await _sharedPreferences.remove("yama_custom_theme_$slot");
    await _sharedPreferences.remove("yama_custom_theme_name_$slot");
    notifyListeners();
  }

  /// All appearance settings as a JSON theme file.
  String exportAppearance() => const JsonEncoder.withIndent("  ").convert({
        "yamaTheme": 1,
        "settings": {for (final key in appearanceDefaults.keys) key: _value(key)},
      });

  /// Loads a theme produced by [exportAppearance]. Returns false if the text
  /// is not a YaMa theme.
  Future<bool> importAppearance(String json) async {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map || decoded["settings"] is! Map) {
      return false;
    }
    final Map settings = decoded["settings"] as Map;
    await applyAppearance({
      for (final entry in settings.entries)
        if (entry.key is String) entry.key as String: entry.value as Object?,
    });
    return true;
  }

  SettingsService(
    this._sharedPreferences
  );

  Future<void> set(String key, bool value) async {
    await _sharedPreferences.setBool(key, value);
    notifyListeners();
  }

  Future<void> setAppHighlightAnimationEnabled(bool value) async {
    return set(_appHighlightAnimationEnabledKey, value);
  }

  Future<void> setAppKeyClickEnabled(bool value) async {
    return set(_appKeyClickEnabledKey, value);
  }

  Future<void> setAutoHideAppBarEnabled(bool value) async {
    return set(_autoHideAppBar, value);
  }

  Future<void> setGradientUuid(String value) async {
    await _sharedPreferences.setString(_gradientUuidKey, value);
    notifyListeners();
  }

  Future<void> setBackButtonAction(String value) async {
    await _sharedPreferences.setString(_backButtonAction, value);
    notifyListeners();
  }

  Future<void> setDateTimeFormat(String dateFormatString, String timeFormatString) async {
    await Future.wait([
      _sharedPreferences.setString(_dateFormat, dateFormatString),
      _sharedPreferences.setString(_timeFormat, timeFormatString)
    ]);
    notifyListeners();
  }

  Future<void> setShowCategoryTitles(bool show) async {
    return set(_showCategoryTitles, show);
  }

  Future<void> setShowDateInStatusBar(bool show) async {
    return set(_showDateInStatusBar, show);
  }

  Future<void> setShowTimeInStatusBar(bool show) async {
    return set(_showTimeInStatusBar, show);
  }

  Future<void> setCardShape(CardShape value) => setValue(YamaKeys.cardShape, value);
  Future<void> setLabelMode(LabelMode value) => setValue(YamaKeys.labelMode, value);
  Future<void> setFocusZoom(double value) => setValue(YamaKeys.focusZoom, value);
  Future<void> setCornerRadius(int value) => setValue(YamaKeys.cornerRadius, value);
  Future<void> setCardSpacing(int value) => setValue(YamaKeys.cardSpacing, value);
  Future<void> setSectionSpacing(int value) => setValue(YamaKeys.sectionSpacing, value);
  Future<void> setWallpaperDim(int value) => setValue(YamaKeys.wallpaperDim, value);
  Future<void> setWallpaperBlur(int value) => setValue(YamaKeys.wallpaperBlur, value);
}
