/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-16 12:16:08
 * @Description: file content
 */

// import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:weather/weather_library.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/provider.dart';

// a provider provides some actions
MyProvider providerWeather = MyProvider(initContent: initWeather);

List<MyAction> initWeather() {
  List<MyAction> actions = <MyAction>[];
  if (providerWeather.needUpdate()) {
    actions = [
      MyAction(
        name: 'Weather',
        keywords: 'weather forecast',
        action: provideWeather,
        times: List.generate(24, (index) => 0),
        // infoWidgets: weatherInfos,
        suggestWidget: null,
      )
    ];
    // do at the beginning
    provideWeather();
    // set updated
    providerWeather.setUpdated();
  }
  return actions;
}

void provideWeather() async {
  // get location
  // Location location = new Location();
  // location.changeSettings(accuracy: LocationAccuracy.low);
  // bool _serviceEnabled;
  // PermissionStatus _permissionGranted;

  // _serviceEnabled = await location.serviceEnabled();
  // if (!_serviceEnabled) {
  //   _serviceEnabled = await location.requestService();
  //   if (!_serviceEnabled) {
  //     return;
  //   }
  // }

  // _permissionGranted = await location.hasPermission();
  // if (_permissionGranted == PermissionStatus.denied) {
  //   _permissionGranted = await location.requestPermission();
  //   if (_permissionGranted != PermissionStatus.granted) {
  //     return;
  //   }
  // }

  // LocationData position;
  double latitude = 23.046786;
  double longitude = 116.296786;
  try {
    // currently unworkable, I have try location and geolocation
    // amap_location requires an api key, so I will try later
    // LocationData position = await location.getLocation();
    // latitude = position.latitude;
    // longitude = position.longitude;
  } catch (e) {
    infoList.add(
        customInfoWidget(title:"Obtain position error, use default position."));
  } finally {
    // make a weather station to query
    String openWeatherApiKey = "775c57286ee370cf78079b37d408b4e5";
    WeatherStation weatherStation = new WeatherStation(openWeatherApiKey);
    Weather weather;
    try {
      weather = await weatherStation.currentWeather(latitude, longitude);
    } catch (e) {
      infoList.add(customInfoWidget(title: e.toString()));
      return;
    }
    // location info widget
    infoList.add(customInfoWidget(
        title: weather.areaName +
            ", " +
            "(lat, lon) = (" +
            latitude.toString() +
            ", " +
            longitude.toString() +
            ")",
        subtitle: "Here is your location."));
    // weather info widget
    infoList.add(
      customInfoWidget(
          title: weather.temperature.celsius.toString() +
              "°C" +
              ", " +
              weather.weatherMain,
          subtitle: "Here is the weather now."),
    );
  }
}
