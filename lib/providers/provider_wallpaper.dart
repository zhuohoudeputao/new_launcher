/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-16 11:49:35
 * @Description: file content
 */

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:path_provider/path_provider.dart';

MyProvider providerWallpaper = MyProvider(
    name: "Wallpaper",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

final List<String> _wallpaperUrls = [
  "https://picsum.photos/1920/1080",
  "https://picsum.photos/1920/1080?random=1",
  "https://picsum.photos/1920/1080?random=2",
  "https://picsum.photos/1920/1080?random=3",
  "https://picsum.photos/1920/1080?random=4",
];

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: "Refresh Wallpaper",
      keywords: "refresh background wallpaper",
      action: _fetchNewWallpaper,
      times: List.generate(24, (index) => 0),
    )
  ]);
}

Future<void> _initActions() async {
  await _loadSavedWallpaper();
}

Future<void> _update() async {}

Future<void> _loadSavedWallpaper() async {
  final savedWallpaperType =
      await Global.settingsModel.getValue("WallpaperType", "");
  
  if (savedWallpaperType == "network") {
    final url = await Global.settingsModel.getValue("LastWallpaper", "");
    if (url.isNotEmpty) {
      Global.backgroundImageModel.backgroundImage = NetworkImage(url);
      Global.loggerModel.info("Wallpaper restored from network: $url", source: "Wallpaper");
      return;
    }
  } else if (savedWallpaperType == "file") {
    final filePath = await Global.settingsModel.getValue("WallpaperFile", "");
    if (filePath.isNotEmpty && File(filePath).existsSync()) {
      Global.backgroundImageModel.backgroundImage = FileImage(File(filePath));
      Global.loggerModel.info("Wallpaper restored from file: $filePath", source: "Wallpaper");
      return;
    }
  }
  
  Global.loggerModel.info("No saved wallpaper found", source: "Wallpaper");
}

Future<void> _fetchNewWallpaper() async {
  final random = Random();
  final url = _wallpaperUrls[random.nextInt(_wallpaperUrls.length)];

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Global.backgroundImageModel.backgroundImage = NetworkImage(url);
      Global.settingsModel.saveValue("LastWallpaper", url);
      Global.settingsModel.saveValue("WallpaperType", "network");
      Global.infoModel.addInfo("Wallpaper", "Wallpaper updated",
          subtitle: "New background from Picsum");
      Global.loggerModel.info("Wallpaper updated from Picsum: $url", source: "Wallpaper");
    } else {
      Global.infoModel.addInfo("Wallpaper", "Failed to load wallpaper",
          subtitle: "Status: ${response.statusCode}");
      Global.loggerModel.warning("Wallpaper fetch failed: ${response.statusCode}", source: "Wallpaper");
    }
  } catch (e) {
    Global.infoModel.addInfo("Wallpaper", "Wallpaper error", subtitle: e.toString());
    Global.loggerModel.error("Wallpaper error: $e", source: "Wallpaper");
  }
}

Future<void> pickWallpaperFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    final directory = await getApplicationDocumentsDirectory();
    final wallpaperPath = '${directory.path}/saved_wallpaper.jpg';
    
    await File(image.path).copy(wallpaperPath);
    
    Global.backgroundImageModel.backgroundImage = FileImage(File(wallpaperPath));
    Global.settingsModel.saveValue("WallpaperFile", wallpaperPath);
    Global.settingsModel.saveValue("WallpaperType", "file");
    
    Global.infoModel
        .addInfo("Wallpaper", "Wallpaper updated", subtitle: "From gallery");
    Global.loggerModel.info("Wallpaper saved from gallery: $wallpaperPath", source: "Wallpaper");
  }
}
