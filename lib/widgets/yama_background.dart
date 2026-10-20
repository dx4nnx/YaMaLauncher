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

import 'dart:math';
import 'dart:ui' show ImageFilter, TileMode;

import 'package:flauncher/models/yama_settings.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen wallpaper: gradient, picture, solid color or slideshow, with
/// color adjustments, tint, blur, dim and a soft top/bottom shadow.
class YamaBackground extends StatelessWidget {
  const YamaBackground({super.key});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Consumer2<WallpaperService, SettingsService>(
      builder: (context, wallpaper, settings, _) {
        Widget background = _base(wallpaper, settings);
        background = _colorAdjusted(background, settings);

        final double blur = settings.wallpaperBlur.toDouble();
        if (blur > 0) {
          background = ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp),
              child: background,
            ),
          );
        }

        final double dim = (settings.wallpaperDim / 100).clamp(0.0, 0.9).toDouble();
        final double shadow = (settings.wallpaperShadow / 100).clamp(0.0, 1.0).toDouble();

        return Stack(
          key: const Key("background"),
          fit: StackFit.expand,
          children: [
            background,
            if (dim > 0) ColoredBox(color: Colors.black.withOpacity(dim)),
            if (shadow > 0)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(shadow * 0.75),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(shadow),
                    ],
                    stops: const [0, 0.22, 0.5, 1],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _gradient(WallpaperService wallpaper) =>
      DecoratedBox(decoration: BoxDecoration(gradient: wallpaper.gradient.gradient));

  /// Decode pictures at screen size, not their full resolution (often 4K),
  /// which is far faster and lighter on a TV stick.
  Widget _picture(ImageProvider image) => LayoutBuilder(
    builder: (context, constraints) {
      final double ratio = MediaQuery.devicePixelRatioOf(context);
      final double width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
      return _sizedPicture(ResizeImage.resizeIfNeeded((width * ratio).round(), null, image));
    },
  );

  Widget _sizedPicture(ImageProvider image) => Image(
    image: image,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => const SizedBox.expand(),
  );

  Widget _base(WallpaperService wallpaper, SettingsService settings) {
    switch (wallpaper.mode) {
      case WallpaperMode.solid:
        return ColoredBox(color: wallpaper.solidColor);
      case WallpaperMode.image:
        final ImageProvider? image = wallpaper.wallpaper;
        return image == null ? _gradient(wallpaper) : _picture(image);
      case WallpaperMode.slideshow:
      case WallpaperMode.reddit:
      case WallpaperMode.web:
        final ImageProvider? slide = wallpaper.currentImage;
        if (slide == null) {
          return _gradient(wallpaper);
        }
        final SlideEffect transition = _transitionFor(settings.slideshowTransition, wallpaper.slideCounter);
        return _ReadySwitcher(
          image: slide,
          counter: wallpaper.slideCounter,
          // Reddit posts can be phone-shaped; skip those on a TV.
          onPortrait: wallpaper.mode == WallpaperMode.reddit ? wallpaper.nextWallpaper : null,
          placeholder: _gradient(wallpaper),
          builder: (image, counter) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 1400),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current],
            ),
            transitionBuilder: (child, animation) => _transition(transition, child, animation),
            child: KeyedSubtree(
              key: ValueKey(counter),
              child: _picture(image),
            ),
          ),
        );
      case WallpaperMode.gradient:
        return _gradient(wallpaper);
    }
  }

  static SlideEffect _transitionFor(SlideEffect chosen, int counter) {
    if (chosen != SlideEffect.random) {
      return chosen;
    }
    const List<SlideEffect> options = [
      SlideEffect.fade,
      SlideEffect.zoom,
      SlideEffect.slideHorizontal,
      SlideEffect.slideVertical,
    ];
    return options[Random(counter).nextInt(options.length)];
  }

  static Widget _transition(SlideEffect type, Widget child, Animation<double> animation) {
    final Widget faded = FadeTransition(opacity: animation, child: child);
    switch (type) {
      case SlideEffect.zoom:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween<double>(begin: 1.12, end: 1.0).animate(animation), child: child),
        );
      case SlideEffect.slideHorizontal:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.25, 0), end: Offset.zero).animate(animation),
          child: faded,
        );
      case SlideEffect.slideVertical:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation),
          child: faded,
        );
      case SlideEffect.fade:
      case SlideEffect.random:
        return faded;
    }
  }

  /// Brightness, saturation and tint combined into one color matrix.
  Widget _colorAdjusted(Widget child, SettingsService settings) {
    final double saturation = settings.wallpaperSaturation / 100;
    final double brightness = settings.wallpaperBrightness * 2.55;
    final double tint = (settings.wallpaperTintStrength / 100).clamp(0.0, 1.0).toDouble();

    if (saturation == 1 && brightness == 0 && tint == 0) {
      return child;
    }

    final Color tintColor = Color(settings.wallpaperTintColor);
    const double lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final double s = saturation, k = 1 - tint;
    final double inv = 1 - s;

    List<double> row(double r, double g, double b, int channel) => [
      r * k, g * k, b * k, 0, brightness * k + channel * tint,
    ];

    final List<double> matrix = [
      ...row(lr * inv + s, lg * inv, lb * inv, tintColor.red),
      ...row(lr * inv, lg * inv + s, lb * inv, tintColor.green),
      ...row(lr * inv, lg * inv, lb * inv + s, tintColor.blue),
      0, 0, 0, 1, 0,
    ];

    return ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: child);
  }
}

/// Shows the last picture that finished loading, and only switches to a new
/// one once it's downloaded and decoded, so transitions never flash blank.
class _ReadySwitcher extends StatefulWidget {
  final ImageProvider image;
  final int counter;
  final Widget placeholder;
  final Widget Function(ImageProvider image, int counter) builder;

  /// Called instead of showing a picture that is taller than it is wide.
  final VoidCallback? onPortrait;

  const _ReadySwitcher({
    required this.image,
    required this.counter,
    this.onPortrait,
    required this.placeholder,
    required this.builder,
  });

  @override
  State<_ReadySwitcher> createState() => _ReadySwitcherState();
}

class _ReadySwitcherState extends State<_ReadySwitcher> {
  ImageProvider? _shown;
  int _shownCounter = -1;
  int _requested = -1;
  int _skipsInARow = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ReadySwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.counter != widget.counter || oldWidget.image != widget.image) {
      _load();
    }
  }

  void _load() {
    final int counter = widget.counter;
    if (_requested == counter && _shown != null) {
      return;
    }
    _requested = counter;
    final ImageProvider target = widget.image;
    final double ratio = MediaQuery.devicePixelRatioOf(context);
    final double width = MediaQuery.sizeOf(context).width;
    final ImageProvider sized = ResizeImage.resizeIfNeeded((width * ratio).round(), null, target);
    final ImageStream stream = sized.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        stream.removeListener(listener);
        if (!mounted || _requested != counter) return;
        final bool portrait = info.image.height > info.image.width;
        // Give up skipping after a few in a row, so a feed of only tall
        // pictures still shows something.
        if (portrait && widget.onPortrait != null && _skipsInARow < 8) {
          _skipsInARow++;
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onPortrait?.call());
          return;
        }
        _skipsInARow = 0;
        setState(() {
          _shown = target;
          _shownCounter = counter;
        });
      },
      // A picture that fails to load is skipped; the previous one stays.
      onError: (Object _, StackTrace? __) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? shown = _shown;
    if (shown == null) {
      return widget.placeholder;
    }
    return widget.builder(shown, _shownCounter);
  }
}

