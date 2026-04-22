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

class CircularListController extends ScrollController {
  int _itemCount;
  final double itemExtent;
  static const int virtualMultiplier = 100;
  
  late int _virtualCount;
  bool _initialized = false;
  
  CircularListController({int itemCount = 1, this.itemExtent = 100}) 
      : _itemCount = itemCount == 0 ? 1 : itemCount {
    _virtualCount = _itemCount * virtualMultiplier;
  }
  
  int get itemCount => _itemCount;
  
  set itemCount(int value) {
    if (_itemCount != value) {
      _itemCount = value == 0 ? 1 : value;
      _virtualCount = _itemCount * virtualMultiplier;
      _initialized = false;
    }
  }
  
  int get virtualCount => _virtualCount;
  
  int getActualIndex(int virtualIndex) {
    return virtualIndex % _itemCount;
  }
  
  void initPosition() {
    if (!hasClients || _initialized) return;
    final startPoint = (_itemCount * virtualMultiplier ~/ 2) * itemExtent;
    jumpTo(startPoint);
    _initialized = true;
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
        // add providers here to make them accessible
        providers: [
          ChangeNotifierProvider.value(value: Global.themeModel),
          ChangeNotifierProvider.value(value: Global.backgroundImageModel),
          ChangeNotifierProvider.value(value: Global.settingsModel),
          ChangeNotifierProvider.value(value: Global.infoModel),
          ChangeNotifierProvider.value(value: Global.actionModel),
          ChangeNotifierProvider.value(value: Global.loggerModel),
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
  late CircularListController _circularListController;

  @override
  void initState() {
    super.initState();
    _circularListController = CircularListController(itemCount: 1);
  }

  @override
  void dispose() {
    _circularListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionModel = context.watch<ActionModel>();
    String query = actionModel.searchQuery;
    List<Widget> infoList = context.watch<InfoModel>().getFilteredList(query);
    List<Widget> suggestList = actionModel.suggestList;
    
    _circularListController.itemCount = infoList.isEmpty ? 1 : infoList.length;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _circularListController.initPosition();
    });
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Launcher should never pop - this is intentional
      },
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
              // Input Box with Search Icon
              Card(
                child: TextField(
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: "Search apps, settings...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                  controller: context.watch<ActionModel>().inputBoxController,
                  onSubmitted: context.watch<ActionModel>().runFirstAction,
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
                onTap: () {
                  // put away the keyboard
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: ListView.builder(
                  controller: _circularListController,
                  cacheExtent: 500,
                  itemCount: _circularListController.virtualCount,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  itemBuilder: (BuildContext context, int virtualIndex) {
                    final actualIndex = _circularListController.getActualIndex(virtualIndex);
                    if (actualIndex >= infoList.length) {
                      return SizedBox.shrink();
                    }
                    final widget = infoList[infoList.length - actualIndex - 1];
                    return widget;
                  },
                  scrollDirection: Axis.vertical,
                  reverse: true,
                  physics: BouncingScrollPhysics(),
                ),
              )),
            ],
          ),
        ),
      ]),
    );
  }
}
