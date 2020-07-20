import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';

class Setting extends StatefulWidget {
  @override
  SettingState createState() => SettingState();
}

class SettingState extends State<Setting> {
  Timer refreshTimer;

  @override
  void initState() {
    super.initState();
    refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    refreshTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: <Widget>[
      Image(image: backgroundImage, fit: BoxFit.cover),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView.builder(
          itemCount: myData.settingList.length,
          itemBuilder: (BuildContext context, int index) {
            return myData.settingList[index];
          },
          scrollDirection: Axis.vertical,
        ),
      )
    ]);
  }
}
