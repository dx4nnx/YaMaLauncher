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
    final SettingsService settings = context.watch<SettingsService>();
    final CardShape shape = settings.cardShape;
    final bool iconOnly = shape != CardShape.banner;

    if (iconOnly != _imageLoadedAsIcon) {
      _imageLoadedAsIcon = iconOnly;
      _appImageLoadFuture = _loadAppBannerOrIcon(context.read<AppsService>(), iconOnly);
    }

    final double radius = settings.cornerRadius.toDouble();
    final ShapeBorder cardBorder = shape == CardShape.circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final LabelMode labelMode = settings.labelMode;

    return FocusKeyboardListener(
      onPressed: (key) => _onPressed(context, key),
      onLongPress: (key) => _onLongPress(context, key),
      builder: (context) {
        final bool shouldHighlight = _shouldHighlight(context);

        final FocusEffect effect = settings.focusEffect;
        final bool showGlow = effect == FocusEffect.glow && shouldHighlight && !_moving;
        final GlowAnimation glowAnimation =
            settings.appHighlightAnimationEnabled ? settings.glowAnimation : GlowAnimation.still;
        _driveGlow(showGlow ? glowAnimation : null);

        final Color glowColor = Color(settings.glowColor);
        final double glowSize = settings.glowSize.toDouble();
        final bool circle = shape == CardShape.circle;
        final BorderRadius? boxRadius = circle ? null : BorderRadius.circular(radius);
        final double tintStrength = (settings.focusTintStrength / 100).clamp(0.0, 1.0).toDouble();

        final Widget card = AspectRatio(
          aspectRatio: cardAspectRatio(shape),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transformAlignment: Alignment.center,
            transform: _scaleTransform(context, settings.focusZoom),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                if (showGlow)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          shape: circle ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: boxRadius,
                          boxShadow: [_glowShadow(glowAnimation, glowColor, glowSize, _animation.value)],
                        ),
                      ),
                    ),
                  ),
                Material(
                  shape: cardBorder,
                  clipBehavior: Clip.antiAlias,
                  color: shape == CardShape.banner ? null : Color(settings.iconCardColor),
                  elevation: effect == FocusEffect.shadow && shouldHighlight ? 16 : 0,
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
                          Scrollable.ensureVisible(
                            context,
                            // This specific alignment value is not only
                            // to center the focused card in the row while
                            // scrolling, but to prevent the topmost category
                            // title to be hidden by the content above it when
                            // scrolling from the app bar. How it relates to this,
                            // I don't know
                            alignment: 0.5,
                            curve: Curves.easeInOut,
                            duration: Duration(milliseconds: 100)
                          );
                        },
                      ),
                      if (_moving) ..._arrows(),
                      IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          opacity: shouldHighlight ? 0 : (settings.unfocusedDim / 100).clamp(0.0, 0.9).toDouble(),
                          child: Container(color: Colors.black),
                        ),
                      ),
                      if (tintStrength > 0)
                        IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: shouldHighlight ? tintStrength : 0,
                            child: Container(color: Color(settings.focusTintColor)),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showGlow)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: circle ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: boxRadius,
                        border: Border.all(color: glowColor.withOpacity(0.9), width: 2),
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

        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(child: Center(child: card)),
            SizedBox(
              height: appLabelHeight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: labelMode == LabelMode.always || shouldHighlight ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    widget.application.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      shadows: [const Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 6)]
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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

  static BoxShadow _glowShadow(GlowAnimation animation, Color color, double size, double t) {
    switch (animation) {
      case GlowAnimation.still:
        return BoxShadow(color: color.withOpacity(0.8), blurRadius: size, spreadRadius: size * 0.25);
      case GlowAnimation.breathe:
      case GlowAnimation.pulse:
        final double strength = 0.55 + 0.45 * t;
        return BoxShadow(
          color: color.withOpacity(0.35 + 0.55 * t),
          blurRadius: size * strength,
          spreadRadius: size * 0.3 * strength,
        );
      case GlowAnimation.shimmer:
        final HSVColor hsv = HSVColor.fromColor(color);
        final HSVColor shifted = hsv
            .withHue((hsv.hue + 360 * t) % 360)
            .withSaturation(hsv.saturation < 0.35 ? 0.35 : hsv.saturation);
        return BoxShadow(color: shifted.toColor().withOpacity(0.85), blurRadius: size, spreadRadius: size * 0.25);
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
    return FocusManager.instance.highlightMode == FocusHighlightMode.traditional && Focus.of(context).hasFocus;
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
      ),
    );
    if (result == ApplicationInfoPanelResult.reorderApp) {
      setState(() => _moving = true);
    }
  }
}
