import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:provider/provider.dart';

class Setting extends StatefulWidget {
  @override
  SettingState createState() => SettingState();
}

class SettingState extends State<Setting> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> settingList = context.watch<SettingsModel>().settingList;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(fit: StackFit.expand, children: <Widget>[
      Consumer<BackgroundImageModel>(
          builder: (context, BackgroundImageModel background, child) {
        return Image(
            image: context.watch<BackgroundImageModel>().backgroundImage,
            fit: BoxFit.cover);
      }),
      Scaffold(
        backgroundColor: colorScheme.surface.withValues(alpha: 0),
        appBar: AppBar(
          backgroundColor: colorScheme.surface.withValues(alpha: 0),
          surfaceTintColor: colorScheme.surfaceTint,
          scrolledUnderElevation: 0,
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              "Settings",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withValues(alpha: 0.3),
                colorScheme.surface.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              itemCount: settingList.length,
              itemBuilder: (BuildContext context, int index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: child,
                      ),
                    );
                  },
                  child: Selector<SettingsModel, Widget>(
                    selector: (context, provider) => settingList[index],
                    builder: (context, value, child) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: settingList[index],
                    ),
                  ),
                );
              },
              scrollDirection: Axis.vertical,
            ),
          ),
        ),
      )
    ]);
  }
}
