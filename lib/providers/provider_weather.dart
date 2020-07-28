/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 22:37:43
 * @Description: file content
 */

import 'package:new_launcher/ui.dart';
import 'package:weather/weather_library.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

//____________________________________Data
String _openWeatherApiKey;
//________________________________________

/// A provider managing weather information
MyProvider providerWeather = MyProvider(
    name: "Weather",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Weather',
      keywords: 'weather now',
      action: _provideWeather,
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  _getApiKey().then((value) => _provideWeather());
}

Future<void> _update() async {}

/// [providerWeather] will try to obtain your location by sensors first.
/// If it fails, default city in settings will be used to obtain weather.
/// This service is based on OpenWeather, which means that you should provide a api key.
/// Visit [https://openweathermap.org/api] for more.
void _provideWeather() async {
  _getLocation().then((success) {
    if (success) {
      _provideWeatherByLocation();
    } else {
      _provideWeatherByCity();
    }
  });
}

// double _latitude;
// double _longitude;
Future<bool> _getLocation() async {
  // get location by sensors (now is unavailable)
  return false;
}

Future<void> _getApiKey() async {
  String apiKey = "Weather.ApiKey";
  // obtain api key from myData
  _openWeatherApiKey =
      await Global.getValue(apiKey, "775c57286ee370cf78079b37d408b4e5");
}

void _provideWeatherByLocation() {}

Future<void> _provideWeatherByCity() async {
  String cityKey = "Weather.City";
  // obtain city name from myData
  String city = await Global.getValue(cityKey, "Guangzhou");
  // obtain weather by city name
  WeatherFactory weatherFactory = new WeatherFactory(_openWeatherApiKey);
  Weather weather = await weatherFactory.currentWeatherByCityName(city);

  // obtain weather icon
  Icon weatherIcon;
  DateTime now = DateTime.now();
  if (now.isAfter(weather.sunset) || now.isBefore(weather.sunrise)) {
    // nighttime icons
    switch (weather.weatherMain) {
      case "Clouds":
        weatherIcon = Icon(WeatherIcons.night_alt_cloudy);
        break;
      case "Clear":
        weatherIcon = Icon(WeatherIcons.night_clear);
        break;
      case "Rain":
        weatherIcon = Icon(WeatherIcons.night_alt_rain);
        break;
      default:
        weatherIcon = Icon(WeatherIcons.stars);
    }
  } else {
    // daytime icons
    switch (weather.weatherMain) {
      case "Clouds":
        weatherIcon = Icon(WeatherIcons.day_cloudy);
        break;
      default:
        weatherIcon = Icon(WeatherIcons.day_sunny);
    }
  }
  Global.infoModel.addInfoWidget(
      "Weather",
      customInfoWidget(
          title: weather.weatherMain +
              ", " +
              weather.temperature.celsius.toStringAsFixed(1) +
              "°C, " +
              weather.humidity.toString() +
              "%",
          subtitle: weather.areaName +
              // ", " +
              // weather.tempMin.celsius.toString() +
              // "°C" +
              // "-" +
              // weather.tempMax.celsius.toString() +
              // "°C" +
              ", FeelsLike: " +
              weather.tempFeelsLike.celsius.toStringAsFixed(1) +
              "°C",
          icon: weatherIcon));
}
