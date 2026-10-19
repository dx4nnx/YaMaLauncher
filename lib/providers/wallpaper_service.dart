/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 * YaMa Launcher changes Copyright (C) 2026
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
import 'dart:io';
import 'dart:math';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/models/yama_settings.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperService extends ChangeNotifier {
  final FLauncherChannel _fLauncherChannel;
  final SettingsService _settingsService;
  final Random _random = Random();

  File? _wallpaperFile;
  Directory? _slideshowDirectory;

  ImageProvider? _wallpaper;

  List<File> _slides = [];
  List<int> _slideOrder = [];
  int _slidePosition = 0;
  int _slideCounter = 0;
  Timer? _slideTimer;
  int _timerInterval = 0;
  WallpaperMode? _lastMode;

  /// The single picked picture, used in [WallpaperMode.image].
  ImageProvider? get wallpaper => _wallpaper;

  WallpaperMode get mode => _settingsService.wallpaperMode;

  /// Number of pictures in the slideshow.
  int get slideCount => _slides.length;

  /// Current slideshow picture, or null when there is none.
  ImageProvider? get currentSlide =>
      _slides.isEmpty ? null : FileImage(_slides[_slideOrder[_slidePosition % _slideOrder.length]]);

  /// Changes every time the slideshow advances; used to animate transitions.
  int get slideCounter => _slideCounter;

  Color get solidColor => Color(_settingsService.wallpaperSolidColor);

  FLauncherGradient get gradient => FLauncherGradients.all.firstWhere(
        (gradient) => gradient.uuid == _settingsService.gradientUuid,
        orElse: () => FLauncherGradients.greatWhale,
      );

  WallpaperService(this._fLauncherChannel, this._settingsService) :
    _wallpaper = null
  {
    _settingsService.addListener(_onSettingsChanged);
    _init();
  }

  Future<void> _init() async {
    final directory = await getApplicationDocumentsDirectory();
    _wallpaperFile = File("${directory.path}/wallpaper");
    _slideshowDirectory = Directory("${directory.path}/slideshow");

    if (await _wallpaperFile!.exists()) {
      _wallpaper = FileImage(_wallpaperFile!);
    }
    await _loadSlides();
    _onSettingsChanged();
    notifyListeners();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    final WallpaperMode currentMode = mode;
    final int interval = _settingsService.slideshowInterval;
    final bool slideshowActive = currentMode == WallpaperMode.slideshow && _slides.length > 1;

    if (!slideshowActive) {
      _slideTimer?.cancel();
      _slideTimer = null;
      _timerInterval = 0;
    }
    else if (_slideTimer == null || interval != _timerInterval) {
      _restartTimer();
    }

    if (_lastMode != currentMode) {
      _lastMode = currentMode;
      notifyListeners();
    }
  }

  void _restartTimer() {
    _slideTimer?.cancel();
    _timerInterval = max(15, _settingsService.slideshowInterval);
    _slideTimer = Timer.periodic(Duration(seconds: _timerInterval), (_) => nextWallpaper());
  }

  Future<void> _loadSlides() async {
    final Directory? directory = _slideshowDirectory;
    if (directory == null || !await directory.exists()) {
      _slides = [];
    }
    else {
      _slides = directory.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    }
    _shuffle();
  }

  /// A fresh random order, so pictures don't repeat until all were shown.
  void _shuffle() {
    final int previous = _slideOrder.isEmpty ? -1 : _slideOrder[_slidePosition % _slideOrder.length];
    _slideOrder = List<int>.generate(_slides.length, (index) => index)..shuffle(_random);
    if (_slideOrder.length > 1 && _slideOrder.first == previous) {
      _slideOrder.add(_slideOrder.removeAt(0));
    }
    _slidePosition = 0;
  }

  /// Shows the next slideshow picture now (also bound to Play/Pause).
  void nextWallpaper() {
    if (mode != WallpaperMode.slideshow || _slides.length < 2) {
      return;
    }
    _slidePosition++;
    if (_slidePosition >= _slideOrder.length) {
      _shuffle();
    }
    _slideCounter++;
    notifyListeners();
  }

  Future<void> _ensureFileExplorer() async {
    if (!await _fLauncherChannel.checkForGetContentAvailability()) {
      throw NoFileExplorerException();
    }
  }

  Future<void> pickWallpaper() async {
    await _ensureFileExplorer();

    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      await _wallpaperFile!.writeAsBytes(bytes);

      _wallpaper = MemoryImage(bytes);
      await _settingsService.setValue(YamaKeys.wallpaperMode, WallpaperMode.image);
      notifyListeners();
    }
  }

  /// Adds pictures to the slideshow and switches to slideshow mode.
  Future<int> addSlideshowPictures() async {
    await _ensureFileExplorer();

    final List<XFile> picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) {
      return 0;
    }

    final Directory directory = _slideshowDirectory!;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final int stamp = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < picked.length; i++) {
      final Uint8List bytes = await picked[i].readAsBytes();
      await File("${directory.path}/slide_${stamp}_$i").writeAsBytes(bytes);
    }

    await _loadSlides();
    _slideCounter++;
    await _settingsService.setValue(YamaKeys.wallpaperMode, WallpaperMode.slideshow);
    _onSettingsChanged();
    notifyListeners();
    return picked.length;
  }

  Future<void> clearSlideshow() async {
    final Directory? directory = _slideshowDirectory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await _loadSlides();
    if (mode == WallpaperMode.slideshow) {
      await _settingsService.setValue(YamaKeys.wallpaperMode, WallpaperMode.gradient);
    }
    _onSettingsChanged();
    notifyListeners();
  }

  Future<void> setSolidColor(Color color) async {
    await _settingsService.setValue(YamaKeys.wallpaperSolidColor, color.value);
    await _settingsService.setValue(YamaKeys.wallpaperMode, WallpaperMode.solid);
    notifyListeners();
  }

  Future<void> setGradient(FLauncherGradient fLauncherGradient) async {
    final File? file = _wallpaperFile;
    if (file != null && await file.exists()) {
      await file.delete();
    }
    _wallpaper = null;

    await _settingsService.setGradientUuid(fLauncherGradient.uuid);
    await _settingsService.setValue(YamaKeys.wallpaperMode, WallpaperMode.gradient);
    notifyListeners();
  }

  /// Switches back to an already chosen picture or slideshow, if available.
  Future<void> useMode(WallpaperMode newMode) async {
    await _settingsService.setValue(YamaKeys.wallpaperMode, newMode);
    _onSettingsChanged();
    notifyListeners();
  }
}

class NoFileExplorerException implements Exception {}
