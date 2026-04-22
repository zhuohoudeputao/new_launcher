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
import 'package:shared_preferences/shared_preferences.dart';

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

const String _weatherCacheKey = "Weather.Cache";
const Duration _cacheValidity = Duration(minutes: 30);

class ForecastDay {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weathercode;

  ForecastDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weathercode,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'maxTemp': maxTemp,
    'minTemp': minTemp,
    'weathercode': weathercode,
  };

  factory ForecastDay.fromJson(Map<String, dynamic> json) => ForecastDay(
    date: DateTime.parse(json['date']),
    maxTemp: json['maxTemp'],
    minTemp: json['minTemp'],
    weathercode: json['weathercode'],
  );
}

class WeatherCache {
  final double temperature;
  final double windspeed;
  final int weathercode;
  final double latitude;
  final double longitude;
  final String locationName;
  final List<ForecastDay> forecast;
  final DateTime timestamp;

  WeatherCache({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
    required this.latitude,
    required this.longitude,
    this.locationName = '',
    this.forecast = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'windspeed': windspeed,
    'weathercode': weathercode,
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
    'forecast': forecast.map((f) => f.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory WeatherCache.fromJson(Map<String, dynamic> json) => WeatherCache(
    temperature: json['temperature'],
    windspeed: json['windspeed'],
    weathercode: json['weathercode'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    locationName: json['locationName'] ?? '',
    forecast: (json['forecast'] as List?)
        ?.map((f) => ForecastDay.fromJson(f as Map<String, dynamic>))
        .toList() ?? [],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

Future<WeatherCache?> _loadCachedWeather() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cacheStr = prefs.getString(_weatherCacheKey);
    if (cacheStr == null) return null;
    
    final json = jsonDecode(cacheStr) as Map<String, dynamic>;
    final cache = WeatherCache.fromJson(json);
    
    if (DateTime.now().difference(cache.timestamp) < _cacheValidity) {
      return cache;
    }
    return null;
  } catch (e) {
    Global.loggerModel.warning("Failed to load weather cache: $e", source: "Weather");
    return null;
  }
}

Future<void> _saveWeatherCache(WeatherCache cache) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weatherCacheKey, jsonEncode(cache.toJson()));
  } catch (e) {
    Global.loggerModel.warning("Failed to save weather cache: $e", source: "Weather");
  }
}

Future<String> _getLocationName(double latitude, double longitude) async {
  try {
    final response = await http.get(
      Uri.parse("https://geocoding-api.open-meteo.com/v1/reverse?latitude=$latitude&longitude=$longitude&count=1"),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final location = results[0];
        final city = location['name'] ?? '';
        final country = location['country'] ?? '';
        if (city.isNotEmpty && country.isNotEmpty) {
          return '$city, $country';
        } else if (city.isNotEmpty) {
          return city;
        }
      }
    }
  } catch (e) {
    Global.loggerModel.warning("Failed to get location name: $e", source: "Weather");
  }
  
  final latStr = latitude.toStringAsFixed(2);
  final lonStr = longitude.toStringAsFixed(2);
  return "$latStr°, $lonStr°";
}

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
    
    final cached = await _loadCachedWeather();
    if (cached != null) {
      Global.infoModel.addInfoWidget(
          "Weather",
          WeatherCard(cache: cached, onRefresh: _provideWeather),
          title: "Weather");
      Global.loggerModel.info("Weather displayed from cache", source: "Weather");
      return;
    }
  }

  try {
    final response = await http.get(
      Uri.parse(
          "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto"),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final current = data['current_weather'];
      final temp = current['temperature'];
      final wind = current['windspeed'];
      final code = current['weathercode'] ?? 0;

      final locationName = await _getLocationName(latitude, longitude);
      
      List<ForecastDay> forecast = [];
      if (data['daily'] != null) {
        final daily = data['daily'];
        final times = daily['time'] as List?;
        final maxTemps = daily['temperature_2m_max'] as List?;
        final minTemps = daily['temperature_2m_min'] as List?;
        final codes = daily['weathercode'] as List?;
        
        if (times != null && maxTemps != null && minTemps != null && codes != null) {
          for (int i = 0; i < times.length && i < 4; i++) {
            forecast.add(ForecastDay(
              date: DateTime.parse(times[i]),
              maxTemp: maxTemps[i],
              minTemp: minTemps[i],
              weathercode: codes[i],
            ));
          }
        }
      }

      final cache = WeatherCache(
        temperature: temp,
        windspeed: wind,
        weathercode: code,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        forecast: forecast,
        timestamp: DateTime.now(),
      );
      await _saveWeatherCache(cache);

      Global.infoModel.addInfoWidget(
          "Weather",
          WeatherCard(cache: cache, onRefresh: _provideWeather),
          title: "Weather");
      Global.loggerModel.info("Weather updated from API with location and forecast", source: "Weather");
    } else {
      final cached = await _loadCachedWeather();
      if (cached != null) {
        Global.infoModel.addInfoWidget(
            "Weather",
            WeatherCard(cache: cached, onRefresh: _provideWeather),
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
    }
  } catch (e) {
    final cached = await _loadCachedWeather();
    if (cached != null) {
      Global.infoModel.addInfoWidget(
          "Weather",
          WeatherCard(cache: cached, onRefresh: _provideWeather),
          title: "Weather");
      Global.loggerModel.info("Weather displayed from cache due to error", source: "Weather");
    } else {
      Global.infoModel.addInfoWidget(
          "Weather",
          customInfoWidget(
              title: "Weather error",
              subtitle: e.toString(),
              icon: Icon(Icons.error)),
          title: "Weather");
    }
  }
}

class WeatherCard extends StatefulWidget {
  final WeatherCache cache;
  final VoidCallback onRefresh;

  const WeatherCard({
    Key? key,
    required this.cache,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      widget.onRefresh();
    } finally {
      await Future.delayed(Duration(milliseconds: 500));
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cache = widget.cache;
    final condition = _weatherCodes[cache.weathercode] ?? "Unknown";
    final icon = getWeatherIcon(condition);
    
    final now = DateTime.now();
    final cacheAge = now.difference(cache.timestamp);
    final isCached = cacheAge > Duration(minutes: 5);
    
    const Map<int, String> dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    return Card.filled(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 32, color: Theme.of(context).colorScheme.onSurface),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${cache.temperature.toInt()}°C",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          condition,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: _isRefreshing 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, size: 20),
                  onPressed: _isRefreshing ? null : _handleRefresh,
                  tooltip: "Refresh weather",
                ),
              ],
            ),
            if (cache.locationName.isNotEmpty) Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                cache.locationName + (isCached ? " (cached)" : ""),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.air, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                SizedBox(width: 4),
                Text(
                  "Wind: ${cache.windspeed.toInt()} km/h",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (cache.forecast.length > 1) SizedBox(height: 12),
            if (cache.forecast.length > 1) Text(
              "Forecast",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (cache.forecast.length > 1) SizedBox(height: 4),
            if (cache.forecast.length > 1) SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: cache.forecast.skip(1).take(3).map((day) {
                  final dayCondition = _weatherCodes[day.weathercode] ?? "Unknown";
                  final dayIcon = getWeatherIcon(dayCondition);
                  final dayName = dayNames[day.date.weekday] ?? "";
                  
                  return Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Text(dayName, style: TextStyle(fontSize: 11)),
                        Icon(dayIcon, size: 20),
                        Text(
                          "${day.maxTemp.toInt()}°/${day.minTemp.toInt()}°",
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
