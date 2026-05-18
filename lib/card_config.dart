/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-13 00:31:26
 * @Description: CardConfig class and enums for card configuration
 */

import 'package:flutter/material.dart';

/// Enum representing the type of card
enum CardType {
  INFO,
  ACTION,
  SETTINGS,
  UTILITY,
}

/// Enum representing the size of card
enum CardSize {
  SMALL,
  MEDIUM,
  LARGE,
}

/// Enum representing the layout of card
enum CardLayout {
  LIST,
  GRID,
  FULL_WIDTH,
}

/// Configuration class for cards
class CardConfig {
  final String key;
  final Widget widget;
  final CardType type;
  final CardSize size;
  final CardLayout layout;
  final String? title;

  const CardConfig({
    required this.key,
    required this.widget,
    required this.type,
    required this.size,
    required this.layout,
    this.title,
  });

  @override
  String toString() {
    return 'CardConfig(key: $key, type: $type, size: $size, layout: $layout, title: $title)';
  }
}