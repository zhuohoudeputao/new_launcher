/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 22:37:43
 * @Description: file content
 */

import 'package:weather/weather_library.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

// a provider provides some actions
MyProvider providerWeather = MyProvider(initContent: _initWeather);
String _openWeatherApiKey;

List<MyAction> _initWeather() {
  // obtain [OpenWeather] api key
  _getApiKey();
  // build and return actions
  List<MyAction> actions = <MyAction>[];
  if (providerWeather.needUpdate()) {
    actions = [
      MyAction(
        name: 'Weather',
        keywords: 'weather now',
        action: _provideWeather,
        times: List.generate(24, (index) => 0),
        suggestWidget: null,
      ),
    ];
    // do at the beginning
    _provideWeather();
    // set updated
    providerWeather.setUpdated();
  }
  return actions;
}

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

  // // if fail, use default location
  // _latitude = await myData.getValue("latitude");
  // _longitude = await myData.getValue("longitude");
  // _openWeatherApiKey = await myData.getValue("openWeatherApiKey");

  // // if null, store the system default values
  // if (_latitude is! double) {
  //   myData.saveValue("latitude", 23.046786);
  // }
  // if (_longitude is! double) {
  //   myData.saveValue("longitude", 116.296786);
  // }
  // if (_openWeatherApiKey is! String) {
  //   myData.saveValue("openWeatherApiKey", "775c57286ee370cf78079b37d408b4e5");
  // }
  // // re-get
  // _latitude = await myData.getValue("latitude");
  // _longitude = await myData.getValue("longitude");
  // _openWeatherApiKey = await myData.getValue("openWeatherApiKey");

  // try {} catch (e) {
  //   myData.addInfo("Obtain position error, use default position.");
  // } finally {
  //   // make a weather station to query
  //   WeatherFactory weatherFactory = new WeatherFactory(_openWeatherApiKey);
  //   Weather weather;
  //   try {
  //     weather =
  //         await weatherFactory.currentWeatherByLocation(_latitude, _longitude);
  //   } catch (e) {
  //     myData.addInfo(e.toString());
  //     return;
  //   }
  //   // weather info widget
  //   myData.addInfo(
  //       weather.weatherMain +
  //           ", " +
  //           weather.temperature.celsius.toStringAsFixed(1) +
  //           "°C",
  //       subtitle: weather.areaName);
  // }
}

double _latitude;
double _longitude;
Future<bool> _getLocation() async {
  // get location by sensors (now is unavailable)
  return false;
}

Future<void> _getApiKey() async {
  String apiKey = "Weather.ApiKey";
  // obtain api key from myData
  _openWeatherApiKey = await myData.getValue(apiKey);
  if (_openWeatherApiKey == null) {
    _openWeatherApiKey = "775c57286ee370cf78079b37d408b4e5"; // default value
    myData.saveValue(apiKey, _openWeatherApiKey);
  }
}

void _provideWeatherByLocation() {}

Future<void> _provideWeatherByCity() async {
  String cityKey = "Weather.City";
  // obtain city name from myData
  String city = await myData.getValue(cityKey);
  // check if the value is obtained
  if (city == null) {
    city = "Guangzhou";
    myData.saveValue(cityKey, "Guangzhou"); // default value
  }
  // obtain weather by city name
  WeatherFactory weatherFactory = new WeatherFactory(_openWeatherApiKey);
  Weather weather = await weatherFactory.currentWeatherByCityName(city);
  Icon weatherIcon = Icon(WeatherIcons.night_cloudy);
  myData.addInfo(
      weather.weatherMain +
          ", " +
          weather.temperature.celsius.toStringAsFixed(1) +
          "°C",
      subtitle: weather.areaName,
      icon: weatherIcon);
}