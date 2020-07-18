/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 00:46:55
 * @Description: 
 */

import 'package:new_launcher/action.dart';

/// A provider means a service.
/// It should provide actions when it initializes.
class MyProvider {
  /// A mark to check whether this provider needs update.
  bool _updated;

  /// Function to generate actions, returning a list of [MyAction].
  Function _initContent;

  /// Initialization
  MyProvider({
    initContent,
  }) {
    this._updated = false;
    this._initContent = initContent;
  }

  bool needUpdate() {
    if (this._updated == false) {
      return true;
    } else {
      return false;
    }
  }

  void setUpdated() {
    this._updated = true;
  }

  List<MyAction> initContent() {
    return this._initContent.call();
  }
}
