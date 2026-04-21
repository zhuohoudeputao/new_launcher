/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-16 11:49:35
 * @Description: file content
 */

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';

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
      action: _readBackground,
      times: List.generate(24, (index) => 0),
    )
  ]);
}

Future<void> _initActions() async {
  await _readBackground();
}

Future<void> _update() async {
  await _readBackground();
}

Future<void> pickWallpaperFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    Global.backgroundImageModel.backgroundImage = FileImage(
      await _cacheImage(image),
    );
    Global.infoModel
        .addInfo("Wallpaper", "Wallpaper updated", subtitle: "From gallery");
  }
}

Future<dynamic> _cacheImage(XFile image) async {
  return await image.readAsBytes();
}

Future<void> _readBackground() async {
  final random = Random();
  final url = _wallpaperUrls[random.nextInt(_wallpaperUrls.length)];

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Global.backgroundImageModel.backgroundImage = NetworkImage(url);
      Global.infoModel.addInfo("Wallpaper", "Wallpaper updated",
          subtitle: "New background from Picsum");
    } else {
      Global.infoModel.addInfo("Wallpaper", "Failed to load wallpaper",
          subtitle: "Status: ${response.statusCode}");
    }
  } catch (e) {
    Global.infoModel
        .addInfo("Wallpaper", "Wallpaper error", subtitle: e.toString());
  }
}
