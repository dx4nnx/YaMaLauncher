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

/// Appearance settings added by YaMa Launcher.
///
/// Every appearance key lives in [appearanceDefaults], which drives the
/// getters in SettingsService, theme export/import, presets and "reset".

enum FocusEffect { none, shadow, glow }

enum GlowAnimation { still, breathe, pulse, shimmer }

enum WallpaperMode { gradient, image, solid, slideshow }

enum SlideEffect { fade, zoom, slideHorizontal, slideVertical, random }

T enumFromName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((value) => value.name == name, orElse: () => fallback);

abstract class YamaKeys {
  // Layout & cards
  static const cardShape = "card_shape";
  static const labelMode = "label_mode";
  static const focusZoom = "focus_zoom";
  static const cornerRadius = "corner_radius";
  static const cardSpacing = "card_spacing";
  static const sectionSpacing = "section_spacing";
  static const marginLeft = "margin_left";
  static const marginRight = "margin_right";
  static const marginTop = "margin_top";
  static const dockEnabled = "dock_enabled";
  static const dockOpacity = "dock_opacity";
  static const dockBlur = "dock_blur";
  static const hideEmptyCategories = "hide_empty_categories";
  static const iconCardColor = "icon_card_color";

  // Focus
  static const focusEffect = "focus_effect";
  static const glowColor = "glow_color";
  static const glowSize = "glow_size";
  static const glowAnimation = "glow_animation";
  static const focusTintColor = "focus_tint_color";
  static const focusTintStrength = "focus_tint_strength";
  static const unfocusedDim = "unfocused_dim";

  // Wallpaper
  static const wallpaperMode = "wallpaper_mode";
  static const wallpaperSolidColor = "wallpaper_solid_color";
  static const wallpaperDim = "wallpaper_dim";
  static const wallpaperBlur = "wallpaper_blur";
  static const wallpaperTintColor = "wallpaper_tint_color";
  static const wallpaperTintStrength = "wallpaper_tint_strength";
  static const wallpaperBrightness = "wallpaper_brightness";
  static const wallpaperSaturation = "wallpaper_saturation";
  static const wallpaperShadow = "wallpaper_shadow";
  static const slideshowInterval = "slideshow_interval";
  static const slideshowTransition = "slideshow_transition";

  // Clock & text
  static const clockColor = "clock_color";
  static const clockSize = "clock_size";
  static const clockShadow = "clock_shadow";
  static const clockTwoLines = "clock_two_lines";
  static const fontFamily = "font_family";
  static const textScale = "text_scale";
  static const accentColor = "accent_color";

  // Idle
  static const idleTimeout = "idle_timeout";
  static const idleOpacity = "idle_opacity";
}

/// Default value of every appearance setting. The value's runtime type
/// (bool, int, double, String) is the type stored in SharedPreferences.
const Map<String, Object> appearanceDefaults = {
  YamaKeys.cardShape: "banner",
  YamaKeys.labelMode: "focused",
  YamaKeys.focusZoom: 1.1,
  YamaKeys.cornerRadius: 16,
  YamaKeys.cardSpacing: 20,
  YamaKeys.sectionSpacing: 16,
  YamaKeys.marginLeft: 32,
  YamaKeys.marginRight: 32,
  YamaKeys.marginTop: 0,
  YamaKeys.dockEnabled: true,
  YamaKeys.dockOpacity: 10,
  YamaKeys.dockBlur: false,
  YamaKeys.hideEmptyCategories: true,
  YamaKeys.iconCardColor: 0x33FFFFFF,

  YamaKeys.focusEffect: "glow",
  YamaKeys.glowColor: 0xFFBFD7FF,
  YamaKeys.glowSize: 12,
  YamaKeys.glowAnimation: "breathe",
  YamaKeys.focusTintColor: 0xFFFFFFFF,
  YamaKeys.focusTintStrength: 0,
  YamaKeys.unfocusedDim: 12,

  YamaKeys.wallpaperMode: "gradient",
  YamaKeys.wallpaperSolidColor: 0xFF1B2440,
  YamaKeys.wallpaperDim: 0,
  YamaKeys.wallpaperBlur: 0,
  YamaKeys.wallpaperTintColor: 0xFF7FA6FF,
  YamaKeys.wallpaperTintStrength: 0,
  YamaKeys.wallpaperBrightness: 0,
  YamaKeys.wallpaperSaturation: 100,
  YamaKeys.wallpaperShadow: 35,
  YamaKeys.slideshowInterval: 300,
  YamaKeys.slideshowTransition: "fade",

  YamaKeys.clockColor: 0xFFFFFFFF,
  YamaKeys.clockSize: 24,
  YamaKeys.clockShadow: true,
  YamaKeys.clockTwoLines: false,
  YamaKeys.fontFamily: "Nunito",
  YamaKeys.textScale: 100,
  YamaKeys.accentColor: 0xFF9DB8FF,

  YamaKeys.idleTimeout: 0,
  YamaKeys.idleOpacity: 0,
};

/// Soft palette offered in every color picker.
const List<int> yamaPalette = [
  0xFFFFFFFF, // white
  0xFFBFD7FF, // ice blue
  0xFF9DB8FF, // periwinkle
  0xFF7FE0D0, // mint
  0xFFB8F2A6, // spring
  0xFFFFE08A, // butter
  0xFFFFB38A, // peach
  0xFFFF9EB5, // rose
  0xFFD6A8FF, // lilac
  0xFF1B2440, // midnight
  0xFF2B1B3D, // plum night
  0xFF0F2A2A, // deep teal
  0xFF000000, // black
];

const List<String> yamaFonts = ["System", "Nunito", "Quicksand", "Comfortaa", "Inter", "Lexend"];

/// Built-in theme presets. Keys not listed keep their current value.
const Map<String, Map<String, Object>> yamaPresets = {
  "YaMa Glass": appearanceDefaults,
  "Frosted Icons": {
    YamaKeys.cardShape: "square",
    YamaKeys.labelMode: "always",
    YamaKeys.cornerRadius: 24,
    YamaKeys.cardSpacing: 24,
    YamaKeys.dockEnabled: true,
    YamaKeys.dockOpacity: 14,
    YamaKeys.dockBlur: true,
    YamaKeys.iconCardColor: 0x40FFFFFF,
    YamaKeys.focusEffect: "glow",
    YamaKeys.glowColor: 0xFFFFFFFF,
    YamaKeys.glowAnimation: "breathe",
    YamaKeys.wallpaperBlur: 8,
    YamaKeys.wallpaperDim: 10,
    YamaKeys.fontFamily: "Quicksand",
  },
  "Bubble": {
    YamaKeys.cardShape: "circle",
    YamaKeys.labelMode: "focused",
    YamaKeys.focusZoom: 1.2,
    YamaKeys.cardSpacing: 28,
    YamaKeys.iconCardColor: 0x4DFFFFFF,
    YamaKeys.glowColor: 0xFFFF9EB5,
    YamaKeys.glowAnimation: "pulse",
    YamaKeys.dockEnabled: false,
    YamaKeys.fontFamily: "Comfortaa",
    YamaKeys.accentColor: 0xFFFF9EB5,
  },
  "Night Calm": {
    YamaKeys.cardShape: "banner",
    YamaKeys.labelMode: "never",
    YamaKeys.cornerRadius: 12,
    YamaKeys.focusEffect: "shadow",
    YamaKeys.unfocusedDim: 35,
    YamaKeys.wallpaperDim: 45,
    YamaKeys.wallpaperShadow: 60,
    YamaKeys.clockColor: 0xFFFFE08A,
    YamaKeys.dockEnabled: false,
    YamaKeys.fontFamily: "Inter",
    YamaKeys.idleTimeout: 120,
  },
  "Classic FLauncher": {
    YamaKeys.cardShape: "banner",
    YamaKeys.labelMode: "never",
    YamaKeys.focusZoom: 1.1,
    YamaKeys.cornerRadius: 8,
    YamaKeys.cardSpacing: 16,
    YamaKeys.marginLeft: 16,
    YamaKeys.marginRight: 16,
    YamaKeys.dockEnabled: false,
    YamaKeys.focusEffect: "none",
    YamaKeys.unfocusedDim: 10,
    YamaKeys.wallpaperShadow: 0,
    YamaKeys.fontFamily: "System",
    YamaKeys.clockSize: 22,
  },
};
