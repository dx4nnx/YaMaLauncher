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

import 'dart:io';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Custom app icons, kept in a folder that ADB and file managers can reach:
/// `Android/data/app.yama.launcher/files/icons`.
///
/// A picture is used for an app when its name is either the app's package
/// name (`com.netflix.ninja.png`) or the app's name (`netflix.png`,
/// `prime-video.png`; case, spaces and dashes don't matter).
class CustomIconService extends ChangeNotifier {
  static const List<String> _extensions = ["png", "jpg", "jpeg", "webp"];

  /// Words that are often added to icon file names (e.g. youtube-logo.png).
  static const List<String> _noiseWords = ["color", "colour", "icon", "logo", "banner", "app", "tv", "android"];

  final FLauncherChannel _channel;
  Directory? _folder;

  /// File base name (exactly as written) -> file.
  Map<String, File> _byExactName = {};

  /// Simplified file base name -> file.
  Map<String, File> _bySimpleName = {};

  int _generation = 0;

  CustomIconService(this._channel) {
    _init();
  }

  /// Folder to copy icons into with ADB, or null if storage isn't available.
  String? get folderPath => _folder?.path;

  int get count => _byExactName.length;

  /// Changes whenever any icon changes, so cards know to redraw.
  int get generation => _generation;

  static String simplify(String name) => name.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]"), "");

  static String _withoutNoise(String name) {
    String result = name.toLowerCase();
    for (final String word in _noiseWords) {
      result = result.replaceAll(RegExp("(^|[^a-z0-9])$word(?=[^a-z0-9]|\$)"), " ");
    }
    return simplify(result);
  }

  File? _fileFor(String packageName, String appName) =>
      _byExactName[packageName] ?? _bySimpleName[simplify(appName)] ?? _bySimpleName[simplify(packageName)];

  bool hasIcon(String packageName, String appName) => _fileFor(packageName, appName) != null;

  ImageProvider? iconFor(String packageName, String appName) {
    final File? file = _fileFor(packageName, appName);
    return file == null ? null : FileImage(file);
  }

  Future<void> _init() async {
    Directory? base;
    try {
      base = await getExternalStorageDirectory();
    } catch (_) {
      base = null;
    }
    base ??= await getApplicationDocumentsDirectory();
    _folder = Directory("${base.path}/icons");
    try {
      await _folder!.create(recursive: true);
    } catch (_) {}
    await reload();
  }

  /// Re-reads the icons folder (after copying icons over with ADB).
  Future<int> reload() async {
    final Directory? folder = _folder;
    final Map<String, File> exact = {};
    final Map<String, File> simple = {};
    if (folder != null && await folder.exists()) {
      for (final FileSystemEntity entity in folder.listSync()) {
        if (entity is! File) continue;
        final String name = entity.uri.pathSegments.last;
        final int dot = name.lastIndexOf(".");
        if (dot <= 0) continue;
        if (!_extensions.contains(name.substring(dot + 1).toLowerCase())) continue;
        final String base = name.substring(0, dot);
        exact[base] = entity;
        simple.putIfAbsent(simplify(base), () => entity);
        simple.putIfAbsent(_withoutNoise(base), () => entity);
      }
    }
    // Drop cached pictures so replaced files show their new image.
    for (final File file in {..._byExactName.values, ...exact.values}) {
      FileImage(file).evict();
    }
    _byExactName = exact;
    _bySimpleName = simple..remove("");
    _generation++;
    notifyListeners();
    return exact.length;
  }

  /// How many of [apps] (package name, app name) now have a custom icon.
  int matchCount(Iterable<({String packageName, String name})> apps) =>
      apps.where((app) => hasIcon(app.packageName, app.name)).length;

  /// Lets the person pick a picture with another app (e.g. Cx File Explorer).
  /// Returns false if they backed out.
  Future<bool> pickIcon(String packageName) async {
    final List<String> picked = await _channel.pickWithApp();
    if (picked.isEmpty) {
      return false;
    }
    await setIconFromFile(packageName, picked.first);
    return true;
  }

  /// Uses a picture chosen in YaMa's own file browser or another app.
  Future<void> setIconFromFile(String packageName, String path) async {
    final String lower = path.toLowerCase();
    final String extension = _extensions.firstWhere((e) => lower.endsWith(".$e"), orElse: () => "png");
    final Uint8List bytes = await File(path).readAsBytes();
    await _removeExact(packageName);
    await File("${_folder!.path}/$packageName.$extension").writeAsBytes(bytes, flush: true);
    await reload();
  }

  /// Copies every picture in a folder into the icons folder, keeping names,
  /// so `youtube.png` etc. are matched to apps by name.
  Future<int> importFolder(String folderPath) async {
    final List<File> pictures = Directory(folderPath).listSync().whereType<File>().where((file) {
      final String lower = file.path.toLowerCase();
      return _extensions.any((e) => lower.endsWith(".$e"));
    }).toList();
    for (final File picture in pictures) {
      final String name = picture.uri.pathSegments.last;
      await picture.copy("${_folder!.path}/$name");
    }
    await reload();
    return pictures.length;
  }

  /// Copies pictures picked with another app, keeping their names.
  Future<int> importWithApp() async {
    final List<String> picked = await _channel.pickWithApp(multiple: true);
    for (final String path in picked) {
      final File file = File(path);
      await file.copy("${_folder!.path}/${file.uri.pathSegments.last}");
    }
    await reload();
    return picked.length;
  }

  Future<void> resetIcon(String packageName, String appName) async {
    await _removeExact(packageName);
    // Also remove a picture that matched by the app's name.
    final File? byName = _bySimpleName[simplify(appName)];
    if (byName != null && await byName.exists()) {
      FileImage(byName).evict();
      await byName.delete();
    }
    await reload();
  }

  Future<void> _removeExact(String packageName) async {
    final Directory? folder = _folder;
    if (folder == null) return;
    for (final String extension in _extensions) {
      final File file = File("${folder.path}/$packageName.$extension");
      if (await file.exists()) {
        FileImage(file).evict();
        await file.delete();
      }
    }
  }
}
