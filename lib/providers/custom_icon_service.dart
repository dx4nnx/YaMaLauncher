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
import 'dart:typed_data';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Custom app icons, stored as `<package name>.png|jpg|jpeg|webp` in a
/// folder that ADB and file managers can reach:
/// `Android/data/app.yama.launcher/files/icons`.
class CustomIconService extends ChangeNotifier {
  static const List<String> _extensions = ["png", "jpg", "jpeg", "webp"];

  final FLauncherChannel _channel;
  Directory? _folder;
  Map<String, File> _icons = {};
  final Map<String, int> _versions = {};

  CustomIconService(this._channel) {
    _init();
  }

  /// Folder to copy icons into with ADB, or null if storage isn't available.
  String? get folderPath => _folder?.path;

  int get count => _icons.length;

  bool hasIcon(String packageName) => _icons.containsKey(packageName);

  /// Changes whenever this app's icon changes, so cards know to redraw.
  int versionFor(String packageName) => _versions[packageName] ?? 0;

  ImageProvider? iconFor(String packageName) {
    final File? file = _icons[packageName];
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
    final Map<String, File> found = {};
    if (folder != null && await folder.exists()) {
      for (final FileSystemEntity entity in folder.listSync()) {
        if (entity is! File) continue;
        final String name = entity.uri.pathSegments.last;
        final int dot = name.lastIndexOf(".");
        if (dot <= 0) continue;
        final String extension = name.substring(dot + 1).toLowerCase();
        if (!_extensions.contains(extension)) continue;
        found[name.substring(0, dot)] = entity;
      }
    }
    // Drop cached pictures so replaced files show their new image.
    for (final File file in {..._icons.values, ...found.values}) {
      FileImage(file).evict();
    }
    for (final String package in {..._icons.keys, ...found.keys}) {
      _versions[package] = versionFor(package) + 1;
    }
    _icons = found;
    notifyListeners();
    return found.length;
  }

  /// Lets the person pick a picture with their file explorer / gallery app.
  /// Returns false if they backed out.
  Future<bool> pickIcon(String packageName) async {
    if (!await _channel.checkForGetContentAvailability()) {
      throw NoFileExplorerException();
    }
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return false;
    }
    final Uint8List bytes = await picked.readAsBytes();
    final String lower = picked.name.toLowerCase();
    final String extension = _extensions.firstWhere((e) => lower.endsWith(".$e"), orElse: () => "png");
    await _removeFiles(packageName);
    final File file = File("${_folder!.path}/$packageName.$extension");
    await file.writeAsBytes(bytes, flush: true);
    await reload();
    return true;
  }

  /// Uses a picture chosen in YaMa's own file browser.
  Future<void> setIconFromFile(String packageName, String path) async {
    final String lower = path.toLowerCase();
    final String extension = _extensions.firstWhere((e) => lower.endsWith(".$e"), orElse: () => "png");
    final Uint8List bytes = await File(path).readAsBytes();
    await _removeFiles(packageName);
    await File("${_folder!.path}/$packageName.$extension").writeAsBytes(bytes, flush: true);
    await reload();
  }

  Future<void> resetIcon(String packageName) async {
    await _removeFiles(packageName);
    await reload();
  }

  Future<void> _removeFiles(String packageName) async {
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
