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

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// What the browser lets the person choose.
enum BrowseMode { image, folder }

final RegExp _imagePattern = RegExp(r"\.(png|jpe?g|webp|gif)$", caseSensitive: false);

/// Remote-friendly file browser: big rows, folders first, picture
/// thumbnails, internal storage and USB drives. Returns the chosen path,
/// or null if the person backs out.
Future<String?> showYamaFileBrowser(
  BuildContext context, {
  required String title,
  BrowseMode mode = BrowseMode.image,
}) async {
  final bool allowed = await _ensureStoragePermission();
  if (!context.mounted) return null;
  if (!allowed) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("YaMa needs permission to read your files. Allow it in the prompt, "
          "or in Settings → Applications → YaMa Launcher → Permissions."),
    ));
    return null;
  }
  return showDialog<String>(
    context: context,
    builder: (_) => _FileBrowserDialog(title: title, mode: mode),
  );
}

Future<bool> _ensureStoragePermission() async {
  try {
    if (await Permission.storage.isGranted || await Permission.photos.isGranted) {
      return true;
    }
    if ((await Permission.storage.request()).isGranted) {
      return true;
    }
    // Android 13 and newer use the photos permission for pictures.
    return (await Permission.photos.request()).isGranted;
  } catch (_) {
    // If permissions can't be checked, try reading anyway.
    return true;
  }
}

class _Place {
  final String label;
  final String path;
  final IconData icon;

  const _Place(this.label, this.path, this.icon);
}

class _FileBrowserDialog extends StatefulWidget {
  final String title;
  final BrowseMode mode;

  const _FileBrowserDialog({required this.title, required this.mode});

  @override
  State<_FileBrowserDialog> createState() => _FileBrowserDialogState();
}

class _FileBrowserDialogState extends State<_FileBrowserDialog> {
  /// null = the list of drives.
  Directory? _current;
  List<Directory> _folders = [];
  List<File> _images = [];
  String? _error;

  List<_Place> get _places {
    final List<_Place> places = [
      const _Place("Internal storage", "/storage/emulated/0", Icons.sd_storage_outlined),
      const _Place("Downloads", "/storage/emulated/0/Download", Icons.download_outlined),
      const _Place("Pictures", "/storage/emulated/0/Pictures", Icons.photo_library_outlined),
    ];
    try {
      for (final FileSystemEntity entity in Directory("/storage").listSync()) {
        final String name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (entity is Directory && name != "emulated" && name != "self") {
          places.add(_Place("USB / SD card ($name)", entity.path, Icons.usb));
        }
      }
    } catch (_) {}
    return places.where((place) => Directory(place.path).existsSync()).toList();
  }

  void _open(Directory directory) {
    try {
      final List<FileSystemEntity> entries = directory.listSync();
      final List<Directory> folders = entries
          .whereType<Directory>()
          .where((d) => !_name(d.path).startsWith("."))
          .toList()
        ..sort((a, b) => _name(a.path).toLowerCase().compareTo(_name(b.path).toLowerCase()));
      final List<File> images = entries
          .whereType<File>()
          .where((f) => _imagePattern.hasMatch(f.path))
          .toList()
        ..sort((a, b) => _name(a.path).toLowerCase().compareTo(_name(b.path).toLowerCase()));
      setState(() {
        _current = directory;
        _folders = folders;
        _images = images;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = "Couldn't open this folder ($e).");
    }
  }

  void _up() {
    final Directory? current = _current;
    if (current == null) return;
    final bool isPlace = _places.any((place) => place.path == current.path);
    if (isPlace || current.parent.path == current.path) {
      setState(() {
        _current = null;
        _error = null;
      });
    } else {
      _open(current.parent);
    }
  }

  static String _name(String path) {
    final List<String> parts = path.split("/").where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? path : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final Directory? current = _current;

    final List<Widget> rows = [];
    if (current == null) {
      for (final _Place place in _places) {
        rows.add(_row(
          autofocus: rows.isEmpty,
          icon: Icon(place.icon),
          label: place.label,
          onPressed: () => _open(Directory(place.path)),
          trailing: const Icon(Icons.chevron_right),
        ));
      }
    } else {
      rows.add(_row(
        autofocus: true,
        icon: const Icon(Icons.arrow_upward),
        label: "Back",
        onPressed: _up,
      ));
      if (widget.mode == BrowseMode.folder) {
        rows.add(_row(
          icon: const Icon(Icons.check_circle_outline),
          label: "Use this folder (${_images.length} picture${_images.length == 1 ? "" : "s"})",
          onPressed: _images.isEmpty ? null : () => Navigator.of(context).pop(current.path),
        ));
      }
      for (final Directory folder in _folders) {
        rows.add(_row(
          icon: const Icon(Icons.folder_outlined),
          label: _name(folder.path),
          onPressed: () => _open(folder),
          trailing: const Icon(Icons.chevron_right),
        ));
      }
      for (final File image in _images) {
        rows.add(_row(
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              image,
              width: 56,
              height: 40,
              fit: BoxFit.cover,
              cacheWidth: 112,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
            ),
          ),
          label: _name(image.path),
          onPressed: widget.mode == BrowseMode.image ? () => Navigator.of(context).pop(image.path) : null,
        ));
      }
      if (_folders.isEmpty && _images.isEmpty && _error == null) {
        rows.add(const Padding(
          padding: EdgeInsets.all(16),
          child: Text("No folders or pictures here."),
        ));
      }
    }

    return PopScope(
      // Back goes up a folder; at the drive list it closes the browser.
      canPop: current == null,
      onPopInvoked: (didPop) {
        if (!didPop) _up();
      },
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: screen.width * 0.16, vertical: screen.height * 0.07),
        backgroundColor: const Color(0xF7141B2E),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                current?.path ?? "Choose where to look",
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              const Divider(),
              Expanded(
                child: ListView(
                  key: ValueKey(current?.path ?? "places"),
                  children: rows,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
    Widget? trailing,
    bool autofocus = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: TextButton(
          autofocus: autofocus,
          onPressed: onPressed ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                SizedBox(width: 56, child: Center(child: icon)),
                const SizedBox(width: 12),
                Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      );
}
