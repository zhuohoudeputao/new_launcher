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
import 'package:provider/provider.dart';

void main() {
  // SystemUiOverlayStyle systemUiOverlayStyle =
  //     SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  // SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  WidgetsFlutterBinding.ensureInitialized();
  Global.init().then((value) => runApp(MultiProvider(
        // add providers here to make it be an ancestor
        providers: [
          ChangeNotifierProvider.value(value: Global.themeModel),
          ChangeNotifierProvider.value(value: Global.backgroundImageModel),
          ChangeNotifierProvider.value(value: Global.settingsModel)
        ],
        child: MyApp(),
      )));
  // runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
    return Stack(fit: StackFit.expand, children: <Widget>[
      // Image(image: backgroundImage, fit: BoxFit.cover),
      // This consumer is to consume the value of
      Consumer<BackgroundImageModel>(
          builder: (context, BackgroundImageModel background, child) {
        return Image(
            image: context.watch<BackgroundImageModel>().backgroundImage,
            fit: BoxFit.cover);
      }),
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
