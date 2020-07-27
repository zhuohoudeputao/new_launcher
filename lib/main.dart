/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 21:40:17
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/data.dart';
import 'package:provider/provider.dart';

void main() {
  // remove the shadow of status bar
  SystemUiOverlayStyle systemUiOverlayStyle =
      SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  // ensure data bindings
  WidgetsFlutterBinding.ensureInitialized();
  // initialize global values then run app
  Global.init().then((value) => runApp(MultiProvider(
        // add providers here to make them accessible
        providers: [
          ChangeNotifierProvider.value(value: Global.themeModel),
          ChangeNotifierProvider.value(value: Global.backgroundImageModel),
          ChangeNotifierProvider.value(value: Global.settingsModel),
          ChangeNotifierProvider.value(value: Global.infoModel),
          ChangeNotifierProvider.value(value: Global.actionModel),
        ],
        child: MyApp(),
      )));
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
  DateTime _lastReturn; // last return time
  @override
  Widget build(BuildContext context) {
    List<Widget> infoList = context.watch<InfoModel>().infoList;
    List<Widget> suggestList = context.watch<ActionModel>().suggestList;
    return WillPopScope(
      onWillPop: () async {
        if (_lastReturn == null ||
            DateTime.now().difference(_lastReturn) > Duration(seconds: 1)) {
          _lastReturn = DateTime.now();
          return false;
        }
        return true;
      }, // return check
      child: Stack(fit: StackFit.expand, children: <Widget>[
        // Background Image
        Consumer<BackgroundImageModel>(
            builder: (context, BackgroundImageModel background, child) {
          return Image(
              image: context.watch<BackgroundImageModel>().backgroundImage,
              fit: BoxFit.cover);
        }),
        // Main Scaffold
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            verticalDirection: VerticalDirection.up,
            children: <Widget>[
              // Input Box
              Card(
                child: TextField(
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                      hintText: ">_ Input something here.",
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).accentColor, width: 10.0),
                      )),
                  controller: context.watch<ActionModel>().inputBoxController,
                  onEditingComplete:
                      context.watch<ActionModel>().runFirstAction,
                  onChanged: context.watch<ActionModel>().generateSuggestList,
                ),
              ),
              // Suggestion Area
              Container(
                height: 50.0,
                child: ListView.builder(
                  // suggestion displayer
                  itemCount: suggestList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Selector<ActionModel, Widget>(
                      selector: (context, provider) => suggestList[index],
                      builder: (context, value, child) => suggestList[index],
                    );
                  },
                  scrollDirection: Axis.horizontal,
                ),
              ),
              // Information Area
              Expanded(
                  child: GestureDetector(
                onTap: () { // put away the keyboard
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: ListView.builder(
                  // infomation displayer
                  itemCount: infoList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Selector<InfoModel, Widget>(
                      selector: (context, provider) =>
                          infoList[infoList.length - index - 1],
                      builder: (context, value, child) =>
                          infoList[infoList.length - index - 1],
                    );
                  },
                  scrollDirection: Axis.vertical,
                  reverse: true, // reverse the entire infoList and the index
                ),
              )),
            ],
          ),
        ),
      ]),
    );
  }
}
