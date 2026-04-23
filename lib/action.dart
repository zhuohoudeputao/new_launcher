/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-11 10:47:33
 * @Description: file content
 */

class MyAction {
  late String name;
  late String _keywords;
  late void Function() _action;
  late List<int> _times;

  MyAction({
    required String name,
    required String keywords,
    required void Function() action,
    required List<int> times,
  }) {
    this.name = name;
    this._keywords = keywords.toLowerCase();
    this._action = action;
    this._times = times;
  }

  Future<void> action() async {
    _action.call();
    _frequencyIncre();
  }

  int get frequency => _times[DateTime.now().hour];

  Future<void> _frequencyIncre() async {
    _times[DateTime.now().hour] += 1;
  }

  bool canIdentifyBy(String searchStr) {
    return _keywords.contains(searchStr.toLowerCase());
  }
}
