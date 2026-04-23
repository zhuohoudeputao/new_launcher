import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:torch_light/torch_light.dart';

FlashlightModel flashlightModel = FlashlightModel();

MyProvider providerFlashlight = MyProvider(
    name: "Flashlight",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Flashlight toggle',
      keywords: 'flashlight torch light flash lamp toggle',
      action: () => flashlightModel.toggle(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await flashlightModel.init();
  Global.infoModel.addInfoWidget(
      "Flashlight",
      ChangeNotifierProvider.value(
          value: flashlightModel,
          builder: (context, child) => FlashlightCard()),
      title: "Flashlight");
}

Future<void> _update() async {
  await flashlightModel.refresh();
}

class FlashlightModel extends ChangeNotifier {
  bool _isOn = false;
  bool _isAvailable = false;
  bool _isInitialized = false;

  bool get isOn => _isOn;
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      _isAvailable = await TorchLight.isTorchAvailable();
      _isInitialized = true;
      Global.loggerModel.info("Flashlight initialized, available: $isAvailable", source: "Flashlight");
      notifyListeners();
    } catch (e) {
      Global.loggerModel.error("Flashlight init error: $e", source: "Flashlight");
      _isInitialized = true;
      _isAvailable = false;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (!_isAvailable) {
      Global.loggerModel.warning("Flashlight not available", source: "Flashlight");
      return;
    }
    
    try {
      if (_isOn) {
        await TorchLight.disableTorch();
        _isOn = false;
        Global.loggerModel.info("Flashlight turned off", source: "Flashlight");
      } else {
        await TorchLight.enableTorch();
        _isOn = true;
        Global.loggerModel.info("Flashlight turned on", source: "Flashlight");
      }
      notifyListeners();
    } catch (e) {
      Global.loggerModel.error("Flashlight toggle error: $e", source: "Flashlight");
    }
  }

  Future<void> enable() async {
    if (!_isAvailable) return;
    
    try {
      await TorchLight.enableTorch();
      _isOn = true;
      notifyListeners();
      Global.loggerModel.info("Flashlight enabled", source: "Flashlight");
    } catch (e) {
      Global.loggerModel.error("Flashlight enable error: $e", source: "Flashlight");
    }
  }

  Future<void> disable() async {
    if (!_isAvailable) return;
    
    try {
      await TorchLight.disableTorch();
      _isOn = false;
      notifyListeners();
      Global.loggerModel.info("Flashlight disabled", source: "Flashlight");
    } catch (e) {
      Global.loggerModel.error("Flashlight disable error: $e", source: "Flashlight");
    }
  }

  Future<void> refresh() async {
    await init();
  }
}

class FlashlightCard extends StatefulWidget {
  @override
  State<FlashlightCard> createState() => _FlashlightCardState();
}

class _FlashlightCardState extends State<FlashlightCard> {
  @override
  Widget build(BuildContext context) {
    final flashlight = context.watch<FlashlightModel>();
    
    if (!flashlight.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 24),
              SizedBox(width: 12),
              Text("Flashlight: Loading..."),
            ],
          ),
        ),
      );
    }
    
    if (!flashlight.isAvailable) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 24, 
                color: Theme.of(context).colorScheme.onSurfaceVariant),
              SizedBox(width: 12),
              Text(
                "Flashlight not available",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = flashlight.isOn ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final iconData = flashlight.isOn ? Icons.lightbulb : Icons.lightbulb_outline;
    
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(iconData, size: 32, color: iconColor),
                SizedBox(width: 12),
                Text(
                  flashlight.isOn ? "On" : "Off",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            Switch(
              value: flashlight.isOn,
              onChanged: (value) => flashlight.toggle(),
              activeColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}