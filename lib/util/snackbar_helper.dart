import 'package:flutter/material.dart';
import 'dart:async';

/// Global SnackBar helper that ensures SnackBars appear above all modals and dialogs
class SnackBarHelper {
  static OverlayEntry? _currentOverlay;
  static Timer? _currentTimer;

  /// Shows a SnackBar that will appear above all modals and dialogs
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Remove any existing overlay
    _removeCurrentOverlay();

    // Find the root overlay to ensure it appears above all modals
    final overlay = _findRootOverlay(context);

    if (overlay != null) {
      _showOverlaySnackBar(
        overlay,
        message: message,
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: duration,
        action: action,
      );
    } else {
      // Fallback to the original context if root overlay not found
      final fallbackOverlay = Overlay.of(context);
      _showOverlaySnackBar(
        fallbackOverlay,
        message: message,
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: duration,
        action: action,
      );
    }
  }

  /// Shows a SnackBar using overlay for proper z-index control
  static void _showOverlaySnackBar(
    OverlayState overlay, {
    required String message,
    required Color backgroundColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    _currentOverlay = OverlayEntry(
      builder:
          (context) => _AnimatedSnackBar(
            message: message,
            backgroundColor: backgroundColor,
            action: action,
            onDismiss: () => _removeCurrentOverlay(),
          ),
    );

    overlay.insert(_currentOverlay!);

    // Auto-remove after duration
    _currentTimer = Timer(duration, () {
      _removeCurrentOverlay();
    });
  }

  /// Removes the current overlay if it exists
  static void _removeCurrentOverlay() {
    _currentTimer?.cancel();
    _currentTimer = null;
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Shows a success SnackBar
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.green,
      duration: duration,
      action: action,
    );
  }

  /// Shows an error SnackBar
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.red,
      duration: duration,
      action: action,
    );
  }

  /// Shows a warning SnackBar
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.orange,
      duration: duration,
      action: action,
    );
  }

  /// Shows an info SnackBar
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.blue,
      duration: duration,
      action: action,
    );
  }

  /// Finds the root overlay to ensure SnackBars appear above all modals
  static OverlayState? _findRootOverlay(BuildContext context) {
    BuildContext? currentContext = context;

    // Walk up the widget tree to find the root overlay
    while (currentContext != null) {
      try {
        final overlay = Overlay.of(currentContext, rootOverlay: true);
        return overlay;
      } catch (e) {
        // Continue searching if this context doesn't have an overlay
      }

      // Move up the tree
      currentContext = currentContext.findAncestorStateOfType<State>()?.context;
    }

    return null;
  }

  /// Disposes of any existing overlay (call this when the app is disposed)
  static void dispose() {
    _removeCurrentOverlay();
  }
}

/// Animated SnackBar widget with bounce-in and bounce-out animations
class _AnimatedSnackBar extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final SnackBarAction? action;
  final VoidCallback onDismiss;

  const _AnimatedSnackBar({
    required this.message,
    required this.backgroundColor,
    this.action,
    required this.onDismiss,
  });

  @override
  State<_AnimatedSnackBar> createState() => _AnimatedSnackBarState();
}

class _AnimatedSnackBarState extends State<_AnimatedSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1), // Start from bottom
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Start the bounce-in animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismissWithAnimation() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  if (widget.action != null) ...[
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        widget.action!.onPressed();
                        _dismissWithAnimation();
                      },
                      child: Text(
                        widget.action!.label,
                        style: TextStyle(
                          color: widget.action!.textColor ?? Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
