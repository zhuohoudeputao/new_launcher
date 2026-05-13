import 'package:flutter/material.dart';

/// AnimationHelper provides standardized animation constants and utilities
/// for consistent, subtle animations throughout the app.
///
/// Animation style: Subtle & Minimal (Material Design standard)
/// - Durations: 200-300ms range
/// - No spring physics (Curves.elasticOut, Curves.bounceOut avoided)
/// - Respects system accessibility setting (MediaQuery.disableAnimations)
class AnimationHelper {
  /// Default animation duration for standard transitions (250ms)
  static const Duration defaultDuration = Duration(milliseconds: 250);

  /// Fast animation duration for quick feedback animations (150ms)
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// Standard curve for most animations (easeInOut)
  static const Curve standardCurve = Curves.easeInOut;

  /// Alternative curve for enter/exit animations (fastOutSlowIn)
  static const Curve alternativeCurve = Curves.fastOutSlowIn;

  /// Returns whether animations should be shown based on system accessibility settings.
  ///
  /// Checks MediaQuery.disableAnimations to respect user preferences for reduced motion.
  /// Use this before starting any animation to ensure accessibility compliance.
  ///
  /// Example:
  /// ```dart
  /// if (AnimationHelper.shouldAnimate(context)) {
  ///   controller.forward();
  /// }
  /// ```
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }

  /// Returns the default animation duration.
  ///
  /// Use for standard transitions like:
  /// - Widget visibility changes
  /// - Color transitions
  /// - Size changes
  static Duration getStandardDuration() {
    return defaultDuration;
  }

  /// Returns the standard animation curve.
  ///
  /// Use for most animations to maintain consistency across the app.
  static Curve getStandardCurve() {
    return standardCurve;
  }
}