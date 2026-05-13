import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/animation_helper.dart';

/// AnimatedInfoWidget wraps a child widget with fade and slide animations
/// for appearance and disappearance transitions.
///
/// Animation behavior:
/// - Appear: opacity 0.0→1.0, slide Offset(0, 0.1)→Offset.zero (250ms)
/// - Remove: opacity 1.0→0.0, slide Offset.zero→Offset(0, -0.1) (250ms)
///
/// Accessibility: Respects system animation settings via AnimationHelper.shouldAnimate()
class AnimatedInfoWidget extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Whether the widget should be visible (controls appear/remove animation)
  final bool visible;

  /// Callback when remove animation completes
  final VoidCallback? onRemoveComplete;

  const AnimatedInfoWidget({
    super.key,
    required this.child,
    this.visible = true,
    this.onRemoveComplete,
  });

  @override
  State<AnimatedInfoWidget> createState() => _AnimatedInfoWidgetState();
}

class _AnimatedInfoWidgetState extends State<AnimatedInfoWidget> {
  /// Current opacity value (0.0 to 1.0)
  double _opacity = 0.0;

  /// Current slide offset
  Offset _slideOffset = const Offset(0, 0.1);

  /// Whether animations should be shown (from system settings)
  bool _shouldAnimate = true;

  /// Previous visibility state (to detect transitions)
  bool _wasVisible = false;
  
  /// Timer for remove animation completion callback
  /// Must be cancelled in dispose() to prevent memory leaks
  Timer? _removeTimer;
  
  /// Flag to track if widget is disposed
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _wasVisible = widget.visible;
    // Start invisible, will animate to visible on first build
    _opacity = 0.0;
    _slideOffset = const Offset(0, 0.1);

    // Trigger appear animation on first build if visible
    if (widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAppearAnimation();
      });
    }
  }
  
  @override
  void dispose() {
    // Cancel pending timer to prevent memory leaks
    _removeTimer?.cancel();
    _removeTimer = null;
    _isDisposed = true;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shouldAnimate = AnimationHelper.shouldAnimate(context);
  }

  @override
  void didUpdateWidget(AnimatedInfoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect visibility transition
    if (widget.visible != _wasVisible) {
      _wasVisible = widget.visible;

      if (widget.visible) {
        // Appearing: animate from invisible to visible
        _startAppearAnimation();
      } else {
        // Removing: animate from visible to invisible
        _startRemoveAnimation();
      }
    }
  }

  /// Start the appear animation (opacity 0→1, slide Offset(0,0.1)→zero)
  void _startAppearAnimation() {
    setState(() {
      _opacity = 1.0;
      _slideOffset = Offset.zero;
    });
  }

  /// Start the remove animation (opacity 1→0, slide zero→Offset(0,-0.1))
  void _startRemoveAnimation() {
    setState(() {
      if (!_shouldAnimate) {
        // Skip animation, set final state immediately
        _opacity = 0.0;
        _slideOffset = const Offset(0, -0.1);
      } else {
        // Animate to invisible state
        _opacity = 0.0;
        _slideOffset = const Offset(0, -0.1);
      }
    });

    // Cancel any existing timer before creating new one
    _removeTimer?.cancel();
    
    // Call onRemoveComplete after animation duration (or immediately if disabled)
    if (!_shouldAnimate) {
      widget.onRemoveComplete?.call();
    } else {
      // Use Timer instead of Future.delayed for proper disposal
      _removeTimer = Timer(AnimationHelper.defaultDuration, () {
        if (!_isDisposed && mounted) {
          widget.onRemoveComplete?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If animations are disabled, use instant transition
    final duration = _shouldAnimate ? AnimationHelper.defaultDuration : Duration.zero;
    final curve = _shouldAnimate ? AnimationHelper.standardCurve : Curves.linear;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: duration,
      curve: curve,
      child: AnimatedSlide(
        offset: _slideOffset,
        duration: duration,
        curve: curve,
        child: widget.child,
      ),
    );
  }
}