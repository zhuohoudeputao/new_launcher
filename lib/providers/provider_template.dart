import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

MyProvider providerTime = MyProvider(initContent: initTime);


List<MyAction> initTime() {
  List<MyAction> actions = <MyAction>[];
  if (providerTime.needUpdate()) {
    actions.add(MyAction(
      name: "Time now",
      keywords: "time now when",
      action: null,
      times: List.generate(
          24, (index) => 0), 
      suggestWidget: null,
    ));
    // do at the beginning
    
    // set updated
    providerTime.setUpdated();
  }
  return actions;
}