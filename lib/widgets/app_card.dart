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

import 'package:flauncher/app_image_type.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/custom_icon_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../models/app.dart';
import '../models/category.dart';
import '../models/layout_options.dart';
import '../models/yama_settings.dart';

const _validationKeys = [LogicalKeyboardKey.select, LogicalKeyboardKey.enter, LogicalKeyboardKey.gameButtonA];

class AppCard extends StatefulWidget
{
  final App application;
  final Category category;
  final bool autofocus;
  final void Function(AxisDirection) onMove;
  final VoidCallback onMoveEnd;

  const AppCard({
    super.key,
    required this.application,
    required this.category,
    required this.autofocus,
    required this.onMove,
    required this.onMoveEnd,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _moving = false;

  /// Whether this card itself has focus (tracked directly from its InkWell).
  bool _focused = false;

  late Future<Tuple2<AppImageType, ImageProvider>> _appImageLoadFuture;
  late bool _imageLoadedAsIcon;
  late final AnimationController _animation = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 1,
    duration: const Duration(
      milliseconds: 1800,
    ),
  );
  GlowAnimation? _runningGlow;

  @override
  void initState() {
    super.initState();

    FocusManager.instance.addHighlightModeListener(_focusHighlightModeChanged);
    _imageLoadedAsIcon = Provider.of<SettingsService>(context, listen: false).cardShape != CardShape.banner;
    _appImageLoadFuture = _loadAppBannerOrIcon(Provider.of<AppsService>(context, listen: false), _imageLoadedAsIcon);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_focusHighlightModeChanged);
    _animation.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only the settings that change how a card looks. Selecting them (instead
    // of watching every setting) keeps cards from redrawing on unrelated changes.
    final look = context.select<SettingsService, ({
      CardShape shape,
      double radius,
      LabelMode label,
      FocusEffect effect,
      int glowColor,
      double glowSize,
      GlowAnimation glowAnimation,
      double zoom,
      int iconColor,
      int tintColor,
      double tint,
      double dim,
      bool smooth,
    })>((s) => (
      shape: s.cardShape,
      radius: s.cornerRadius.toDouble(),
      label: s.labelMode,
      effect: s.focusEffect,
      glowColor: s.glowColor,
      glowSize: s.glowSize.toDouble(),
      glowAnimation: s.appHighlightAnimationEnabled ? s.glowAnimation : GlowAnimation.still,
      zoom: s.focusZoom,
      iconColor: s.iconCardColor,
      tintColor: s.focusTintColor,
      tint: (s.focusTintStrength / 100).clamp(0.0, 1.0).toDouble(),
      dim: (s.unfocusedDim / 100).clamp(0.0, 0.9).toDouble(),
      smooth: s.smoothMode,
    ));

    // Redraw when this app's custom icon is added, replaced or reset.
    context.select<CustomIconService, int>((s) => s.generation);

    final CardShape shape = look.shape;
    final bool iconOnly = shape != CardShape.banner;

    if (iconOnly != _imageLoadedAsIcon) {
      _imageLoadedAsIcon = iconOnly;
      _appImageLoadFuture = _loadAppBannerOrIcon(context.read<AppsService>(), iconOnly);
    }

    final double radius = look.radius;
    final ShapeBorder cardBorder = shape == CardShape.circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final LabelMode labelMode = look.label;

    return FocusKeyboardListener(
      onPressed: (key) => _onPressed(context, key),
      onLongPress: (key) => _onLongPress(context, key),
      builder: (context) {
        final bool shouldHighlight = _shouldHighlight(context);
        final bool focusedStill = shouldHighlight && !_moving;

        final FocusEffect effect = look.effect;
        // Smooth mode keeps the solid ring but skips the costly glow and shadow.
        final bool showGlow = effect == FocusEffect.glow && focusedStill && !look.smooth;
        _driveGlow(showGlow ? look.glowAnimation : null);

        final Color glowColor = Color(look.glowColor);
        final Color ringColor = effect == FocusEffect.glow ? glowColor : Colors.white;
        final double glowSize = look.glowSize;
        final bool circle = shape == CardShape.circle;
        final BorderRadius? boxRadius = circle ? null : BorderRadius.circular(radius);
        final double tintStrength = look.tint;

        final Widget card = AspectRatio(
          aspectRatio: cardAspectRatio(shape),
          child: AnimatedContainer(
            // A quick, gentle zoom: transforms are cheap even on slow TVs.
            duration: Duration(milliseconds: look.smooth ? 130 : 180),
            curve: Curves.easeOutCubic,
            transformAlignment: Alignment.center,
            transform: _scaleTransform(context, look.zoom),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                if (showGlow) _glowLayer(look.glowAnimation, glowColor, glowSize, circle, boxRadius),
                RepaintBoundary(
                  child: Material(
                    shape: cardBorder,
                    clipBehavior: Clip.antiAlias,
                    color: shape == CardShape.banner ? null : Color(look.iconColor),
                    elevation: effect == FocusEffect.shadow && shouldHighlight && !look.smooth ? 16 : 0,
                    shadowColor: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        InkWell(
                          autofocus: widget.autofocus,
                          focusColor: Colors.transparent,
                          customBorder: cardBorder,
                          child: _appImage(shape),
                          onTap: () => _onPressed(context, LogicalKeyboardKey.enter),
                          onLongPress: () => _onLongPress(context, LogicalKeyboardKey.enter),
                          onFocusChange: (focused) {
                            if (focused != _focused) {
                              setState(() => _focused = focused);
                            }
                            if (focused) {
                              // Short, eased scroll: smooth to the eye, but over before
                              // the remote's next press measures card positions.
                              Scrollable.ensureVisible(
                                context,
                                alignment: 0.5,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                        ),
                        if (_moving) ..._arrows(),
                        if (look.dim > 0)
                          IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 140),
                              opacity: shouldHighlight ? 0 : 1,
                              child: ColoredBox(color: Colors.black.withOpacity(look.dim)),
                            ),
                          ),
                        if (shouldHighlight && tintStrength > 0)
                          IgnorePointer(child: ColoredBox(color: Color(look.tintColor).withOpacity(tintStrength))),
                      ],
                    ),
                  ),
                ),
                // Solid ring on the selected card, faded in so moving feels smooth.
                IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    opacity: focusedStill ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: circle ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: boxRadius,
                        border: Border.all(
                          color: effect == FocusEffect.none ? Colors.white : ringColor,
                          width: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (labelMode == LabelMode.never) {
          return card;
        }

        final bool showLabel = labelMode == LabelMode.always || shouldHighlight;
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(child: Center(child: card)),
            SizedBox(
              height: appLabelHeight,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: showLabel
                    ? Text(
                        widget.application.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: shouldHighlight ? FontWeight.w600 : FontWeight.w400,
                          color: shouldHighlight ? Colors.white : Colors.white70,
                          shadows: [const Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 3)],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The glow is drawn once and cached (RepaintBoundary); breathe and pulse
  /// only fade it in and out, which is cheap. Shimmer recolors every frame.
  Widget _glowLayer(GlowAnimation animation, Color color, double size, bool circle, BorderRadius? radius) {
    Widget shadow(Color c) => DecoratedBox(
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius,
        boxShadow: [BoxShadow(color: c.withOpacity(0.85), blurRadius: size, spreadRadius: size * 0.3)],
      ),
    );

    switch (animation) {
      case GlowAnimation.still:
        return IgnorePointer(child: RepaintBoundary(child: shadow(color)));
      case GlowAnimation.breathe:
      case GlowAnimation.pulse:
        return IgnorePointer(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_animation),
            child: RepaintBoundary(child: shadow(color)),
          ),
        );
      case GlowAnimation.shimmer:
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final HSVColor hsv = HSVColor.fromColor(color);
              final HSVColor shifted = hsv
                  .withHue((hsv.hue + 360 * _animation.value) % 360)
                  .withSaturation(hsv.saturation < 0.35 ? 0.35 : hsv.saturation);
              return shadow(shifted.toColor());
            },
          ),
        );
    }
  }

  /// Starts or stops the glow animation to match [animation] (null = off).
  void _driveGlow(GlowAnimation? animation) {
    if (animation == null || animation == GlowAnimation.still) {
      if (_animation.isAnimating) {
        _animation.stop();
      }
      _runningGlow = null;
      return;
    }
    if (_runningGlow == animation && _animation.isAnimating) {
      return;
    }
    _runningGlow = animation;
    switch (animation) {
      case GlowAnimation.pulse:
        _animation.duration = const Duration(milliseconds: 750);
        _animation.repeat(reverse: true);
      case GlowAnimation.shimmer:
        _animation.duration = const Duration(milliseconds: 3000);
        _animation.repeat();
      case GlowAnimation.breathe:
      case GlowAnimation.still:
        _animation.duration = const Duration(milliseconds: 1800);
        _animation.repeat(reverse: true);
    }
  }

  Future<Tuple2<AppImageType, ImageProvider>> _loadAppBannerOrIcon(AppsService service, bool iconOnly) async {
    Uint8List bytes = Uint8List(0);
    AppImageType type = AppImageType.Banner;

    if (!iconOnly) {
      bytes = await service.getAppBanner(widget.application.packageName);
    }

    if (bytes.isEmpty) {
      type = AppImageType.Icon;
      bytes = await service.getAppIcon(widget.application.packageName);
    }

    return Tuple2(type, MemoryImage(bytes));
  }

  Widget _appImage(CardShape shape)
  {
    App app = widget.application;

    // A custom icon (picked on the TV or copied with ADB) replaces the app's own.
    final ImageProvider? custom = context.read<CustomIconService>().iconFor(app.packageName, app.name);
    if (custom != null) {
      return Ink.image(
        image: custom,
        fit: BoxFit.cover,
        onImageError: (_, __) {},
      );
    }

    return FutureBuilder(
      future: _appImageLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Tuple2<AppImageType, ImageProvider> tuple = snapshot.data!;

          if (tuple.item1 == AppImageType.Banner) {
            return Ink.image(image: tuple.item2, fit: BoxFit.cover);
          }
          else if (shape != CardShape.banner) {
            return Center(
              child: FractionallySizedBox(
                widthFactor: shape == CardShape.circle ? 0.62 : 0.72,
                heightFactor: shape == CardShape.circle ? 0.62 : 0.72,
                child: Ink.image(image: tuple.item2, fit: BoxFit.contain),
              ),
            );
          }
          else {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Ink.image(
                      image: tuple.item2,
                      height: double.maxFinite,
                    ),
                  ),
                  Flexible(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        app.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
        else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                app.name,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              )
            ),
          );
        }
        else {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 0, width: 16),
                Text("Loading")
              ],
            ),
          );
        }
      }
    );
  }

  void _focusHighlightModeChanged(FocusHighlightMode mode)
  {
    setState(() { });
  }

  bool _shouldHighlight(BuildContext context)
  {
    return FocusManager.instance.highlightMode == FocusHighlightMode.traditional && _focused;
  }

  Matrix4 _scaleTransform(BuildContext context, double zoom) {
    double scale = 1.0;
    if (!_moving && _shouldHighlight(context)) {
      scale = zoom;
    }
    return Matrix4.diagonal3Values(scale, scale, 1.0);
  }

  List<Widget> _arrows() => [
      _arrow(Alignment.centerLeft, Icons.keyboard_arrow_left, () {
        widget.onMove(AxisDirection.left);
      }),
      _arrow(Alignment.topCenter, Icons.keyboard_arrow_up, () {
        widget.onMove(AxisDirection.up);
      }),
      _arrow(Alignment.bottomCenter, Icons.keyboard_arrow_down, () {
        widget.onMove(AxisDirection.down);
      }),
      _arrow(Alignment.centerRight, Icons.keyboard_arrow_right, () {
        widget.onMove(AxisDirection.right);
      })
  ];

  Widget _arrow(Alignment alignment, IconData icon, VoidCallback onTap) =>
      Align(
        alignment: alignment,
        child: Ink(
          decoration: ShapeDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.8),
            shape: CircleBorder()
          ),
          child: SizedBox(
            height: 36,
            width: 36,
            child: IconButton(
              icon: Icon(icon, size: 24),
              onPressed: onTap,
              padding: EdgeInsets.all(0)
            )
          )
        )
      );

  KeyEventResult _onPressed(BuildContext context, LogicalKeyboardKey? key) {
    if (_moving) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Scrollable.ensureVisible(context,
          alignment: 0.1, duration: const Duration(milliseconds: 100), curve: Curves.easeInOut));
      if (key == LogicalKeyboardKey.arrowLeft) {
        widget.onMove(AxisDirection.left);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        widget.onMove(AxisDirection.up);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        widget.onMove(AxisDirection.right);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        widget.onMove(AxisDirection.down);
      } else if (_validationKeys.contains(key) || key == LogicalKeyboardKey.escape) {
        setState(() => _moving = false);
        widget.onMoveEnd();
      } else {
        return KeyEventResult.ignored;
      }

      return KeyEventResult.handled;
    } else if (_validationKeys.contains(key)) {
      context.read<AppsService>().launchApp(widget.application);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onLongPress(BuildContext context, LogicalKeyboardKey? key) {
    if (!_moving && (key == null || longPressableKeys.contains(key))) {
      _showPanel(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _showPanel(BuildContext context) async {
    final result = await showDialog<ApplicationInfoPanelResult>(
      context: context,
      builder: (context) => ApplicationInfoPanel(
        category: widget.category,
        application: widget.application,
        applicationIcon: context.read<CustomIconService>().iconFor(widget.application.packageName, widget.application.name),
      ),
    );
    if (result == ApplicationInfoPanelResult.reorderApp) {
      setState(() => _moving = true);
    }
  }
}
