/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-13 00:31:26
 * @Description: Tests for CardConfig class and enums
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_launcher/card_config.dart';

void main() {
  group('CardType enum', () {
    test('should have INFO value', () {
      expect(CardType.INFO, isNotNull);
    });

    test('should have ACTION value', () {
      expect(CardType.ACTION, isNotNull);
    });

    test('should have SETTINGS value', () {
      expect(CardType.SETTINGS, isNotNull);
    });

    test('should have UTILITY value', () {
      expect(CardType.UTILITY, isNotNull);
    });

    test('should have exactly 4 values', () {
      expect(CardType.values.length, equals(4));
    });
  });

  group('CardSize enum', () {
    test('should have SMALL value', () {
      expect(CardSize.SMALL, isNotNull);
    });

    test('should have MEDIUM value', () {
      expect(CardSize.MEDIUM, isNotNull);
    });

    test('should have LARGE value', () {
      expect(CardSize.LARGE, isNotNull);
    });

    test('should have exactly 3 values', () {
      expect(CardSize.values.length, equals(3));
    });
  });

  group('CardLayout enum', () {
    test('should have LIST value', () {
      expect(CardLayout.LIST, isNotNull);
    });

    test('should have GRID value', () {
      expect(CardLayout.GRID, isNotNull);
    });

    test('should have FULL_WIDTH value', () {
      expect(CardLayout.FULL_WIDTH, isNotNull);
    });

    test('should have exactly 3 values', () {
      expect(CardLayout.values.length, equals(3));
    });
  });

  group('CardConfig class', () {
    test('should construct with all required parameters', () {
      final widget = Container();
      final config = CardConfig(
        key: 'test_key',
        widget: widget,
        type: CardType.INFO,
        size: CardSize.MEDIUM,
        layout: CardLayout.LIST,
      );

      expect(config.key, equals('test_key'));
      expect(config.widget, equals(widget));
      expect(config.type, equals(CardType.INFO));
      expect(config.size, equals(CardSize.MEDIUM));
      expect(config.layout, equals(CardLayout.LIST));
      expect(config.title, isNull);
    });

    test('should construct with optional title parameter', () {
      final widget = Container();
      final config = CardConfig(
        key: 'test_key',
        widget: widget,
        type: CardType.ACTION,
        size: CardSize.SMALL,
        layout: CardLayout.GRID,
        title: 'Test Title',
      );

      expect(config.key, equals('test_key'));
      expect(config.widget, equals(widget));
      expect(config.type, equals(CardType.ACTION));
      expect(config.size, equals(CardSize.SMALL));
      expect(config.layout, equals(CardLayout.GRID));
      expect(config.title, equals('Test Title'));
    });

    test('should have const constructor', () {
      const widget = SizedBox();
      const config = CardConfig(
        key: 'const_key',
        widget: widget,
        type: CardType.SETTINGS,
        size: CardSize.LARGE,
        layout: CardLayout.FULL_WIDTH,
      );

      expect(config.key, equals('const_key'));
    });

    test('should have toString method for debugging', () {
      final widget = Container();
      final config = CardConfig(
        key: 'debug_key',
        widget: widget,
        type: CardType.UTILITY,
        size: CardSize.MEDIUM,
        layout: CardLayout.LIST,
        title: 'Debug Title',
      );

      final str = config.toString();
      expect(str, contains('CardConfig'));
      expect(str, contains('debug_key'));
      expect(str, contains('UTILITY'));
      expect(str, contains('MEDIUM'));
      expect(str, contains('LIST'));
      expect(str, contains('Debug Title'));
    });

    test('should support all CardType values', () {
      final widget = Container();
      
      final infoConfig = CardConfig(
        key: 'info',
        widget: widget,
        type: CardType.INFO,
        size: CardSize.SMALL,
        layout: CardLayout.LIST,
      );
      expect(infoConfig.type, equals(CardType.INFO));

      final actionConfig = CardConfig(
        key: 'action',
        widget: widget,
        type: CardType.ACTION,
        size: CardSize.MEDIUM,
        layout: CardLayout.GRID,
      );
      expect(actionConfig.type, equals(CardType.ACTION));

      final settingsConfig = CardConfig(
        key: 'settings',
        widget: widget,
        type: CardType.SETTINGS,
        size: CardSize.LARGE,
        layout: CardLayout.FULL_WIDTH,
      );
      expect(settingsConfig.type, equals(CardType.SETTINGS));

      final utilityConfig = CardConfig(
        key: 'utility',
        widget: widget,
        type: CardType.UTILITY,
        size: CardSize.SMALL,
        layout: CardLayout.LIST,
      );
      expect(utilityConfig.type, equals(CardType.UTILITY));
    });

    test('should support all CardSize values', () {
      final widget = Container();
      
      final smallConfig = CardConfig(
        key: 'small',
        widget: widget,
        type: CardType.INFO,
        size: CardSize.SMALL,
        layout: CardLayout.LIST,
      );
      expect(smallConfig.size, equals(CardSize.SMALL));

      final mediumConfig = CardConfig(
        key: 'medium',
        widget: widget,
        type: CardType.INFO,
        size: CardSize.MEDIUM,
        layout: CardLayout.LIST,
      );
      expect(mediumConfig.size, equals(CardSize.MEDIUM));

      final largeConfig = CardConfig(
        key: 'large',
        widget: widget,
        type: CardType.INFO,
        size: CardSize.LARGE,
        layout: CardLayout.LIST,
      );
      expect(largeConfig.size, equals(CardSize.LARGE));
    });

    test('should support all CardLayout values', () {
      final widget = Container();
      
      final listConfig = CardConfig(
        key: 'list',
        widget: widget,
        type: CardType.INFO,
        size: CardSize.SMALL,
        layout: CardLayout.LIST,
      );
      expect(listConfig.layout, equals(CardLayout.LIST));

      final gridConfig = CardConfig(
        key: 'grid',
        widget: widget,
        type: CardType.INFO,
        size: CardSize.SMALL,
        layout: CardLayout.GRID,
      );
      expect(gridConfig.layout, equals(CardLayout.GRID));

      final fullWidthConfig = CardConfig(
        key: 'fullwidth',
        widget: widget,
        type: CardType.INFO,
        size: CardSize.SMALL,
        layout: CardLayout.FULL_WIDTH,
      );
      expect(fullWidthConfig.layout, equals(CardLayout.FULL_WIDTH));
    });
  });
}