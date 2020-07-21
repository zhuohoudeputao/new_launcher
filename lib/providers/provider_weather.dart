/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-22 01:34:53
 * @Description: file content
 */

import 'package:weather/weather_library.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/provider.dart';

// a provider provides some actions
MyProvider providerWeather = MyProvider(initContent: _initWeather);

List<MyAction> _initWeather() {
  List<MyAction> actions = <MyAction>[];
  if (providerWeather.needUpdate()) {
    actions = [
      MyAction(
        name: 'Weather',
        keywords: 'weather forecast',
        action: _provideWeather,
        times: List.generate(24, (index) => 0),
        suggestWidget: null,
      )
    ];
    // do at the beginning
    _provideWeather();
    // set updated
    providerWeather.setUpdated();
  }
  return actions;
}

double _latitude;
double _longitude;
String _openWeatherApiKey;

/// [providerWeather] will try to obtain your location by sensors first.
/// If it fails, default location (latitude and longitude) in settings will be used to obtain weather.
/// This service is based on OpenWeather, which means that you should provide a api key.
/// Visit [https://openweathermap.org/api] for more.
void _provideWeather() async {
  // get location by sensors (now is unavailable)

  // if fail, use default location
  _latitude = await myData.getValue("latitude");
  _longitude = await myData.getValue("longitude");
  _openWeatherApiKey = await myData.getValue("openWeatherApiKey");

  // if null, store the system default values
  if (_latitude is! double) {
    myData.saveValue("latitude", 23.046786);
  }
  if (_longitude is! double) {
    myData.saveValue("longitude", 116.296786);
  }
  if (_openWeatherApiKey is! String) {
    myData.saveValue("openWeatherApiKey", "775c57286ee370cf78079b37d408b4e5");
  }
  // re-get
  _latitude = await myData.getValue("latitude");
  _longitude = await myData.getValue("longitude");
  _openWeatherApiKey = await myData.getValue("openWeatherApiKey");

  try {
    // currently unworkable, I have try location and geolocation
    // amap_location requires an api key, so I will try later
    // LocationData position = await location.getLocation();
    // latitude = position.latitude;
    // longitude = position.longitude;
  } catch (e) {
    infoList.add(customInfoWidget(
        title: "Obtain position error, use default position."));
  } finally {
    // make a weather station to query
    WeatherFactory weatherFactory = new WeatherFactory(_openWeatherApiKey);
    Weather weather;
    try {
      weather = await weatherFactory.currentWeatherByLocation(_latitude, _longitude);
    } catch (e) {
      infoList.add(customInfoWidget(title: e.toString()));
      return;
    }
    // weather info widget
    infoList.add(
      customInfoWidget(
          title: weather.temperature.celsius.toStringAsFixed(1) +
              "°C, " +
              weather.weatherMain,
          subtitle: weather.areaName +
              ", (lat, lon) = (" +
              _latitude.toString() +
              ", " +
              _longitude.toString() +
              ")"),
    );
  }
}
