/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 18:09:05
 * @Description: file content
 */

import 'package:flutter/material.dart';
// Contains some custom widgets here

/// ``customInfoWidget`` is designed for displaying a message
/// with informations. The most important part of a "info" should be
/// displayed on title area. And the second important part is displayed
/// on subtitle.
Widget customInfoWidget(
    {required String title,
    String subtitle = "",
    Widget? icon,
    void Function()? onTap}) {
  return Card(
    child: ListTile(
      title: Text(
        title,
        textAlign: TextAlign.left,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: icon,
    ),
  );
}

/// ``customSuggestWidget`` is designed for displaying a suggest action
/// above the input box.
Widget customSuggestWidget(
    {required String name, required void Function() onPressed}) {
  return TextButton(
    onPressed: onPressed,
    child: Text(name),
  );
}

Widget customTextSettingWidget(
    {required String key,
    required var value,
    required void Function(String) onSubmitted}) {
  return Card(
    child: ListTile(
      // leading: icon,
      title: TextField(
        textAlign: TextAlign.left,
        style: TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: value.toString(),
          labelText: key,
          // helperText: key,
          border: InputBorder.none,
        ),
        onSubmitted: onSubmitted,
        // controller: TextEditingController()..text=value.toString(),
      ),
    ),
  );
}

// Widget customBoolSettingWidget(
//     {String key, bool value, void Function(bool) onChanged}) {
//   return Card(
//     child: ListTile(
//       // leading: icon,
//       title: Text(
//         key,
//         textAlign: TextAlign.left,
//         style: TextStyle(fontWeight: FontWeight.bold),
//       ),
//       subtitle: Text("is " + value.toString()),
//       trailing: Switch(value: value, onChanged: onChanged),
//     ),
//   );
// }

class CustomBoolSettingWidget extends StatefulWidget {
  final String settingKey;
  final bool value;
  final void Function(bool) onChanged;

  const CustomBoolSettingWidget({
    Key? key,
    required this.settingKey,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CustomBoolSettingWidget> createState() =>
      CustomBoolSettingWidgetState();
}

class CustomBoolSettingWidgetState extends State<CustomBoolSettingWidget> {
  late String key;
  late bool value;
  late void Function(bool) onChanged;
  late String subtitle;

  @override
  void initState() {
    super.initState();
    key = widget.settingKey;
    value = widget.value;
    onChanged = widget.onChanged;
    subtitle = "is " + value.toString();
  }

  void updateUI(bool newValue) {
    setState(() {
      value = newValue;
      subtitle = "is " + newValue.toString();
      onChanged.call(newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        // leading: icon,
        title: Text(
          key,
          textAlign: TextAlign.left,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Switch(value: value, onChanged: updateUI),
      ),
    );
  }
}
