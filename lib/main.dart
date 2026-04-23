/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 21:40:17
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/providers/provider_battery.dart';
import 'package:new_launcher/providers/provider_calculator.dart';
import 'package:new_launcher/providers/provider_flashlight.dart';
import 'package:new_launcher/providers/provider_notes.dart';
import 'package:new_launcher/providers/provider_stopwatch.dart';
import 'package:new_launcher/providers/provider_timer.dart';
import 'package:new_launcher/providers/provider_worldclock.dart';
import 'package:new_launcher/providers/provider_countdown.dart';
import 'package:new_launcher/providers/provider_unitconverter.dart';
import 'package:new_launcher/providers/provider_pomodoro.dart';
import 'package:new_launcher/providers/provider_clipboard.dart';
import 'package:new_launcher/providers/provider_todo.dart';
import 'package:new_launcher/providers/provider_qrcode.dart';
import 'package:new_launcher/providers/provider_random.dart';
import 'package:new_launcher/providers/provider_color.dart';
import 'package:new_launcher/providers/provider_currency.dart';
import 'package:new_launcher/providers/provider_bookmarks.dart';
import 'package:new_launcher/providers/provider_habit.dart';
import 'package:new_launcher/providers/provider_meditation.dart';
import 'package:new_launcher/providers/provider_water.dart';
import 'package:new_launcher/providers/provider_mood.dart';
import 'package:new_launcher/providers/provider_expense.dart';
import 'package:new_launcher/providers/provider_numberbase.dart';
import 'package:new_launcher/providers/provider_calendar.dart';
import 'package:new_launcher/providers/provider_progress.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

class SearchTextField extends StatefulWidget {
  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = Global.actionModel.inputBoxController;
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clearText() {
    _controller.clear();
    Global.actionModel.updateSearchQuery('');
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final actionModel = context.watch<ActionModel>();
    return TextField(
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: "Search cards...",
        prefixIcon: Icon(Icons.search),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: _clearText,
                tooltip: "Clear search",
              )
            : null,
        border: InputBorder.none,
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
      ),
      controller: _controller,
      onChanged: actionModel.updateSearchQuery,
    );
  }
}

void main() {
  // remove the shadow of status bar
  SystemUiOverlayStyle systemUiOverlayStyle =
      SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  // ensure data bindings
  WidgetsFlutterBinding.ensureInitialized();
  // initialize global values then run app
Global.init().then((value) => runApp(MultiProvider(
        providers: [
            ChangeNotifierProvider.value(value: Global.themeModel),
            ChangeNotifierProvider.value(value: Global.backgroundImageModel),
            ChangeNotifierProvider.value(value: Global.settingsModel),
            ChangeNotifierProvider.value(value: Global.infoModel),
            ChangeNotifierProvider.value(value: Global.actionModel),
            ChangeNotifierProvider.value(value: Global.loggerModel),
            ChangeNotifierProvider.value(value: appModel),
            ChangeNotifierProvider.value(value: allAppsModel),
            ChangeNotifierProvider.value(value: appStatisticsModel),
            ChangeNotifierProvider.value(value: batteryModel),
            ChangeNotifierProvider.value(value: flashlightModel),
            ChangeNotifierProvider.value(value: notesModel),
            ChangeNotifierProvider.value(value: timerModel),
            ChangeNotifierProvider.value(value: stopwatchModel),
            ChangeNotifierProvider.value(value: calculatorModel),
            ChangeNotifierProvider.value(value: worldClockModel),
            ChangeNotifierProvider.value(value: countdownModel),
            ChangeNotifierProvider.value(value: unitConverterModel),
            ChangeNotifierProvider.value(value: pomodoroModel),
            ChangeNotifierProvider.value(value: clipboardModel),
            ChangeNotifierProvider.value(value: todoModel),
            ChangeNotifierProvider.value(value: qrModel),
            ChangeNotifierProvider.value(value: randomModel),
ChangeNotifierProvider.value(value: colorModel),
            ChangeNotifierProvider.value(value: currencyModel),
            ChangeNotifierProvider.value(value: bookmarksModel),
            ChangeNotifierProvider.value(value: habitModel),
            ChangeNotifierProvider.value(value: meditationModel),
            ChangeNotifierProvider.value(value: waterModel),
            ChangeNotifierProvider.value(value: moodModel),
            ChangeNotifierProvider.value(value: expenseModel),
            ChangeNotifierProvider.value(value: numberBaseModel),
            ChangeNotifierProvider.value(value: progressModel),
           ],
          child: MyApp(),
         )));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Global.actionModel.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    Global.refreshTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: context.watch<ThemeModel>().themeData,
      home: MyHomePage(),
      navigatorKey: navigatorKey,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _refreshAllProviders() async {
    Global.loggerModel.info("Manual refresh triggered", source: "Main");
    for (MyProvider provider in Global.providerList) {
      try {
        await provider.init();
      } catch (e) {
        Global.loggerModel.warning("Provider ${provider.name} refresh error: $e", source: "Main");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionModel = context.watch<ActionModel>();
    String query = actionModel.searchQuery;
    List<Widget> infoList = context.watch<InfoModel>().getFilteredList(query);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
      },
      child: Stack(fit: StackFit.expand, children: <Widget>[
        Consumer<BackgroundImageModel>(
            builder: (context, BackgroundImageModel background, child) {
          return Image(
              image: context.watch<BackgroundImageModel>().backgroundImage,
              fit: BoxFit.cover);
        }),
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            verticalDirection: VerticalDirection.up,
            children: <Widget>[
              Card.filled(
                color: Theme.of(context).cardColor,
                child: SearchTextField(),
              ),
              if (query.isNotEmpty && infoList.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Text(
                    "${infoList.length} ${infoList.length == 1 ? 'result' : 'results'}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: RefreshIndicator(
                  onRefresh: _refreshAllProviders,
                  child: ListView.builder(
                    cacheExtent: 500,
                    itemCount: infoList.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemBuilder: (BuildContext context, int index) {
                      final widget = infoList[infoList.length - index - 1];
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: widget,
                      );
                    },
                    scrollDirection: Axis.vertical,
                    reverse: true,
                    physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  ),
                ),
              )),
            ],
          ),
        ),
      ]),
    );
  }
}
