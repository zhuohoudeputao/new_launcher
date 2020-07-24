/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 21:40:17
 * @Description: file content
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/data.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        // primaryColor: Colors.blue[100],
        accentColor: Colors.blue[100],
        // cardColor: Colors.grey[900],
        // primaryColor: Colors.black87,
        // cardColor: Colors.white24,
        // cardColor: Colors.transparent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
      navigatorKey: navigatorKey,
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
  /// Data binding is too difficult to achieve, so I refresh UI by timer.
  /// Though it is not perfect.
  Timer refreshTimer;

  @override
  void initState() {
    super.initState();
    refreshTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {});
    });
    myData.initServices();
  }

  @override
  void dispose() {
    super.dispose();
    refreshTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Stack(fit: StackFit.expand, children: <Widget>[
      Image(image: backgroundImage, fit: BoxFit.cover),
      Scaffold(
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
                      borderSide: BorderSide(
                          color: Theme.of(context).accentColor, width: 10.0),
                    )),
                controller: myData.inputBoxController,
                onEditingComplete: myData.runFirstAction,
                onChanged: myData.generateSuggestList,
              ),
            ),
            Container(
              height: 50.0,
              child: ListView.builder(
                // suggestion displayer
                itemCount: myData.suggestList.length,
                itemBuilder: (BuildContext context, int index) {
                  return myData.suggestList[index];
                },
                scrollDirection: Axis.horizontal,
              ),
            ),
            Expanded(
              child: ListView.builder(
                // infomation displayer
                itemCount: myData.infoList.length,
                itemBuilder: (BuildContext context, int index) {
                  return myData.infoList[
                      myData.infoList.length - index - 1]; // reverse index
                },
                scrollDirection: Axis.vertical,
                reverse: true, // reverse the entire infoList and the index
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
