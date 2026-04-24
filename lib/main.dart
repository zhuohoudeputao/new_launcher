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
import 'package:new_launcher/providers/provider_anniversary.dart';
import 'package:new_launcher/providers/provider_sleep.dart';
import 'package:new_launcher/providers/provider_counter.dart';
import 'package:new_launcher/providers/provider_tip.dart';
import 'package:new_launcher/providers/provider_bmi.dart';
import 'package:new_launcher/providers/provider_metronome.dart';
import 'package:new_launcher/providers/provider_flashcard.dart';
import 'package:new_launcher/providers/provider_workout.dart';
import 'package:new_launcher/providers/provider_age.dart';
import 'package:new_launcher/providers/provider_percentage.dart';
import 'package:new_launcher/providers/provider_quickcontacts.dart';
import 'package:new_launcher/providers/provider_shoppinglist.dart';
import 'package:new_launcher/providers/provider_caffeine.dart';
import 'package:new_launcher/providers/provider_subscription.dart';
import 'package:new_launcher/providers/provider_parking.dart';
import 'package:new_launcher/providers/provider_gratitude.dart';
import 'package:new_launcher/providers/provider_debt.dart';
import 'package:new_launcher/providers/provider_interval_timer.dart';
import 'package:new_launcher/providers/provider_textencoder.dart';
import 'package:new_launcher/providers/provider_morse.dart';
import 'package:new_launcher/providers/provider_timestamp.dart';
import 'package:new_launcher/providers/provider_textcase.dart';
import 'package:new_launcher/providers/provider_wordcounter.dart';
import 'package:new_launcher/providers/provider_dayscalculator.dart';
import 'package:new_launcher/providers/provider_loremipsum.dart';
import 'package:new_launcher/providers/provider_uuid.dart';
import 'package:new_launcher/providers/provider_passwordstrength.dart';
import 'package:new_launcher/providers/provider_moonphase.dart';
import 'package:new_launcher/providers/provider_reactiontime.dart';
import 'package:new_launcher/providers/provider_decisionmaker.dart';
import 'package:new_launcher/providers/provider_rockpaperscissors.dart';
import 'package:new_launcher/providers/provider_whosturn.dart';
import 'package:new_launcher/providers/provider_tictactoe.dart';
import 'package:new_launcher/providers/provider_memorygame.dart';
import 'package:new_launcher/providers/provider_hangman.dart';
import 'package:new_launcher/providers/provider_sudoku.dart';
import 'package:new_launcher/providers/provider_minesweeper.dart';
import 'package:new_launcher/providers/provider_2048.dart';
import 'package:new_launcher/providers/provider_wordle.dart';
import 'package:new_launcher/providers/provider_typingtest.dart';
import 'package:new_launcher/providers/provider_simon.dart';
import 'package:new_launcher/providers/provider_sequence.dart';
import 'package:new_launcher/providers/provider_filesize.dart';
import 'package:new_launcher/providers/provider_sunposition.dart';
import 'package:new_launcher/providers/provider_romannumerals.dart';
import 'package:new_launcher/providers/provider_palindrome.dart';
import 'package:new_launcher/providers/provider_nato.dart';
import 'package:new_launcher/providers/provider_speed.dart';
import 'package:new_launcher/providers/provider_volume.dart';
import 'package:new_launcher/providers/provider_angle.dart';
import 'package:new_launcher/providers/provider_prime.dart';
import 'package:new_launcher/providers/provider_ascii.dart';
import 'package:new_launcher/providers/provider_datarate.dart';
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
            ChangeNotifierProvider.value(value: calendarModel),
            ChangeNotifierProvider.value(value: progressModel),
            ChangeNotifierProvider.value(value: anniversaryModel),
            ChangeNotifierProvider.value(value: sleepModel),
            ChangeNotifierProvider.value(value: counterModel),
ChangeNotifierProvider.value(value: tipModel),
            ChangeNotifierProvider.value(value: bmiModel),
            ChangeNotifierProvider.value(value: metronomeModel),
            ChangeNotifierProvider.value(value: flashcardModel),
            ChangeNotifierProvider.value(value: workoutModel),
            ChangeNotifierProvider.value(value: ageModel),
            ChangeNotifierProvider.value(value: percentageModel),
            ChangeNotifierProvider.value(value: quickContactsModel),
            ChangeNotifierProvider.value(value: shoppingListModel),
            ChangeNotifierProvider.value(value: caffeineModel),
            ChangeNotifierProvider.value(value: subscriptionModel),
            ChangeNotifierProvider.value(value: parkingModel),
            ChangeNotifierProvider.value(value: gratitudeModel),
            ChangeNotifierProvider.value(value: debtModel),
            ChangeNotifierProvider.value(value: intervalTimerModel),
            ChangeNotifierProvider.value(value: textEncoderModel),
            ChangeNotifierProvider.value(value: morseCodeModel),
            ChangeNotifierProvider.value(value: timestampModel),
            ChangeNotifierProvider.value(value: textCaseModel),
            ChangeNotifierProvider.value(value: wordCounterModel),
            ChangeNotifierProvider.value(value: daysCalculatorModel),
            ChangeNotifierProvider.value(value: loremIpsumModel),
ChangeNotifierProvider.value(value: uuidModel),
            ChangeNotifierProvider.value(value: passwordStrengthModel),
            ChangeNotifierProvider.value(value: moonPhaseModel),
            ChangeNotifierProvider.value(value: reactionTimeModel),
            ChangeNotifierProvider.value(value: decisionMakerModel),
ChangeNotifierProvider.value(value: rockPaperScissorsModel),
            ChangeNotifierProvider.value(value: whosTurnModel),
            ChangeNotifierProvider.value(value: ticTacToeModel),
            ChangeNotifierProvider.value(value: memoryGameModel),
ChangeNotifierProvider.value(value: hangmanModel),
            ChangeNotifierProvider.value(value: sudokuModel),
            ChangeNotifierProvider.value(value: minesweeperModel),
            ChangeNotifierProvider.value(value: game2048Model),
            ChangeNotifierProvider.value(value: wordleModel),
            ChangeNotifierProvider.value(value: typingTestModel),
ChangeNotifierProvider.value(value: simonModel),
             ChangeNotifierProvider.value(value: sequenceModel),
             ChangeNotifierProvider.value(value: fileSizeConverterModel),
ChangeNotifierProvider.value(value: sunPositionModel),
              ChangeNotifierProvider.value(value: romanNumeralsModel),
              ChangeNotifierProvider.value(value: palindromeModel),
              ChangeNotifierProvider.value(value: natoPhoneticModel),
              ChangeNotifierProvider.value(value: speedConverterModel),
              ChangeNotifierProvider.value(value: volumeConverterModel),
              ChangeNotifierProvider.value(value: angleConverterModel),
              ChangeNotifierProvider.value(value: primeModel),
              ChangeNotifierProvider.value(value: asciiModel),
              ChangeNotifierProvider.value(value: dataRateConverterModel),
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
