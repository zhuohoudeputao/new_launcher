/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 22:37:43
 * @Description:
 */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

MyProvider providerWeather = MyProvider(
    name: "Weather",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

const Map<int, String> _weatherCodes = {
  0: "Clear sky",
  1: "Mainly clear",
  2: "Partly cloudy",
  3: "Overcast",
  45: "Fog",
  48: "Depositing rime fog",
  51: "Light drizzle",
  53: "Moderate drizzle",
  55: "Dense drizzle",
  61: "Slight rain",
  63: "Moderate rain",
  65: "Heavy rain",
  71: "Slight snow",
  73: "Moderate snow",
  75: "Heavy snow",
  77: "Snow grains",
  80: "Slight rain showers",
  81: "Moderate rain showers",
  82: "Violent rain showers",
  85: "Slight snow showers",
  86: "Heavy snow showers",
  95: "Thunderstorm",
  96: "Thunderstorm with hail",
  99: "Thunderstorm with heavy hail",
};

IconData getWeatherIcon(String condition) {
  final lower = condition.toLowerCase();
  if (lower.contains("clear") || lower.contains("sunny")) {
    return Icons.wb_sunny;
  } else if (lower.contains("cloud") || lower.contains("overcast")) {
    return Icons.cloud;
  } else if (lower.contains("rain") || lower.contains("drizzle")) {
    return Icons.water_drop;
  } else if (lower.contains("snow")) {
    return Icons.ac_unit;
  } else if (lower.contains("thunder")) {
    return Icons.flash_on;
  } else if (lower.contains("fog")) {
    return Icons.foggy;
  }
  return Icons.cloud;
}

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Weather',
      keywords: 'weather now',
      action: () => _provideWeather(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  Global.infoModel.addInfoWidget(
    "Weather",
    customInfoWidget(
      title: "Weather",
      subtitle: "Loading...",
      icon: Icon(Icons.cloud),
    ),
    title: "Weather",
  );
  await _provideWeather();
}

Future<void> _update() async {
  await _provideWeather();
}

Future<void> _provideWeather() async {
  double latitude = 40.71;
  double longitude = -74.01;

  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        latitude = position.latitude;
        longitude = position.longitude;
      }
    }
  } catch (e) {
    Global.loggerModel.warning("Weather geolocation error: $e", source: "Weather");
  }

  try {
    final response = await http.get(
      Uri.parse(
          "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true"),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final current = data['current_weather'];
      final temp = current['temperature'];
      final wind = current['windspeed'];
      final code = current['weathercode'] ?? 0;
      final condition = _weatherCodes[code] ?? "Unknown";

      Global.infoModel.addInfoWidget(
          "Weather",
          customInfoWidget(
              title: "$temp°C - $condition",
              subtitle: "Wind: $wind km/h",
              icon: Icon(getWeatherIcon(condition))),
          title: "Weather");
    } else {
      Global.infoModel.addInfoWidget(
          "Weather",
          customInfoWidget(
              title: "Weather error",
              subtitle: "Status: ${response.statusCode}",
              icon: Icon(Icons.error)),
          title: "Weather");
    }
  } catch (e) {
    Global.infoModel.addInfoWidget(
        "Weather",
        customInfoWidget(
            title: "Weather error",
            subtitle: e.toString(),
            icon: Icon(Icons.error)),
        title: "Weather");
  }
}
