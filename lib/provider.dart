/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 00:46:55
 * @Description: 
 */

/// A provider means a service which provides actions.
/// An action actually contains a real action (a function to manipulate data and produce info widgets to the [infoList])
/// and a suggest widget (a button generated for quickly accessing the action).
/// When users input something in the input box, [suggestList] will display those suggest widget related to the input.
/// At the same time, the actions will changed for some reasons. For example, an action will no longer be used.
/// It means that a proivider must have the ability to be aware of the setting or data changing.
/// Therefore, a provider must manage all actions, and provides suitable suggest widgets for [suggestList].
///
/// The logic of [MyProvider]:
/// 1. get all setting values and check if it's enabled ("Enabled" is also a setting)
/// 2. provide actions and take actions when initializing (asynchronously)
/// 3. provide settings and take actions when settings are changing (asynchronously)
class MyProvider {
  /// A provider needs a name or key to identify it. The name must be UpperCase.
  String name;

  /// A provider provide services when it's enabled. Default is true.
  bool isEnabled = true;

  /// A provider generate actions to actionList, and this must be done when this provider is initializing if it's enabled.
  /// This should be asynchronous.
  void Function() provideActions;

  /// Some actions will be taken when it's initializing.
  void Function() initActions;
  bool initialized = false;

  /// Some actions will be taken when settings changed.
  void Function() update;

  MyProvider(
      {String name,
      void Function() provideActions,
      void Function() initActions,
      void Function() update}) {
    // obtain settings from share_preferences
    this.name = name;
    this.provideActions = provideActions;
    this.initActions = initActions;
    this.update = update;
  }
}
