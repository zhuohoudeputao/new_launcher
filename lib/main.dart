/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 18:37:29
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/provider_time.dart';
import 'package:new_launcher/provider_app.dart';
import 'package:new_launcher/provider_weather.dart';

void main() {
  // SystemUiOverlayStyle systemUiOverlayStyle =
  //     SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  // SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Launcher',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.deepPurple,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
        title: "New Launcher",
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // The list for displaying infomations
  // List<Widget> _infoList = <Widget>[];
  // The list for displaying action suggestions
  List<Widget> _suggestList = <Widget>[];
  Map<Widget, MyAction> _suggestWidgetToAction = <Widget, MyAction>{};

  // Map<MyProvider, List<MyAction>> _ac
  List<MyProvider> _providerList = [providerTime, providerWeather, providerApp];
  List<MyAction> _actionList = <MyAction>[];

  // ui controller
  TextEditingController _editingController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    // initialize actionList
    initSuggestion();
    // initialize suggestList
    // Todo: sort by times in an hour
    // _suggestList = _suggestWidgetToAction.keys;

    // initialize infoList
  }

  void initSuggestion() {
    for (MyProvider provider in _providerList) {
      List<MyAction> actions = provider.initContent.call();
      _actionList.addAll(actions);
      for (MyAction action in actions) {
        _suggestWidgetToAction[action.suggestWidget] = action;
      }
    }
  }

  void _handleInput(String input) {
    /** when input is submitted
     * Divide and conquer
     */
    input = input.toLowerCase();
    switch (input) {
      default:
        if (_suggestList.isNotEmpty) {
          setState(() {
            MyAction actionNow = _suggestWidgetToAction[_suggestList[0]];
            actionNow.action.call();
          });
        } else {
          _dontKnow();
        }
    }
    // Record

    // Clear the input field
    _editingController.text = "";
  }

  String inputBefore = "";
  void _provideSuggestion(String input) {
    /**
     * generate suggestList when inputting
     */
    initSuggestion();
    setState(() {
      _suggestList.clear();
      // generate suggestList
      for (MyAction action in _actionList) {
        if (action.keywords.contains(input.toLowerCase())) {
          _suggestList.add(action.suggestWidget);
        }
      }
    });
  }

  void _dontKnow() {
    setState(() {
      infoList.add(customInfoWidget(title: "I don't know what to do 😂"));
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
        image: NetworkImage(
            'http://www.005.tv/uploads/allimg/171017/14033330Y-27.jpg'),
        fit: BoxFit.cover,
      )),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            verticalDirection: VerticalDirection.up,
            children: <Widget>[
              Card(
                child: TextField(
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                      hintText: ">_ Input something here.",
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.deepPurple, width: 10.0),
                      )),
                  controller: _editingController,
                  onSubmitted: _handleInput,
                  onChanged: _provideSuggestion,
                ),
              ),
              Container(
                height: 40.0,
                child: ListView.builder(
                  // suggestion displayer
                  itemCount: _suggestList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _suggestList[index];
                  },
                  scrollDirection: Axis.horizontal,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  // infomation displayer
                  itemCount: infoList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return infoList[infoList.length - index - 1]; // reverse index
                  },
                  scrollDirection: Axis.vertical,
                  reverse: true, // reverse the entire infoList and the index
                  controller: _scrollController,
                ),
              ),
            ],
          )),
    );
  }
}
