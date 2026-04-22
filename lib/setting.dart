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
    final brightness = Theme.of(context).brightness;
    final textColor = brightness == Brightness.dark ? Colors.white : Colors.black87;
    
    return Stack(fit: StackFit.expand, children: <Widget>[
      Consumer<BackgroundImageModel>(
          builder: (context, BackgroundImageModel background, child) {
        return Image(
            image: context.watch<BackgroundImageModel>().backgroundImage,
            fit: BoxFit.cover);
      }),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Settings",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: ListView.builder(
            itemCount: settingList.length,
            itemBuilder: (BuildContext context, int index) {
              return Selector<SettingsModel, Widget>(
                selector: (context, provider) => settingList[index],
                builder: (context, value, child) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: settingList[index],
                ),
              );
            },
            scrollDirection: Axis.vertical,
          ),
        ),
      )
    ]);
  }
}
