import 'package:new_launcher/provider.dart';

MyProvider providerTemplate = MyProvider(
    name: "Template",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {}

Future<void> _initActions() async {}

Future<void> _update() async {}
