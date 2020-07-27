import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:provider/provider.dart';

class Setting extends StatefulWidget {
  @override
  SettingState createState() => SettingState();
}

class SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    List<Widget> settingList = context.watch<SettingsModel>().settingList;
    return Stack(fit: StackFit.expand, children: <Widget>[
      // Image(image: backgroundImage, fit: BoxFit.cover),
      Consumer<BackgroundImageModel>(
          builder: (context, BackgroundImageModel background, child) {
        return Image(
            image: context.watch<BackgroundImageModel>().backgroundImage,
            fit: BoxFit.cover);
      }),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView.builder(
          itemCount: settingList.length,
          itemBuilder: (BuildContext context, int index) {
            return Selector<SettingsModel, Widget>(
              selector: (context, provider) => settingList[index],
              builder: (context, value, child) => settingList[index],
            );
          },
          scrollDirection: Axis.vertical,
        ),
      )
    ]);
  }
}
