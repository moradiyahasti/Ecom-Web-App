import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnackbarService {
  static OverlayEntry? _currentSnackbar;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required bool isSuccess,
    VoidCallback? onAction,
    String? actionText,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove existing snackbar
    _currentSnackbar?.remove();
    _currentSnackbar = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _PremiumSnackBar(
        title: title,
        message: message,
        isSuccess: isSuccess,
        onDismiss: () {
          overlayEntry.remove();
          _currentSnackbar = null;
        },
        onAction: onAction,
        actionText: actionText,
      ),
    );

    _currentSnackbar = overlayEntry;
    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        _currentSnackbar = null;
      }
    });
  }

  static void dismiss() {
    _currentSnackbar?.remove();
    _currentSnackbar = null;
  }
}

class _PremiumSnackBar extends StatefulWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const _PremiumSnackBar({
    required this.title,
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  State<_PremiumSnackBar> createState() => _PremiumSnackBarState();
}

class _PremiumSnackBarState extends State<_PremiumSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isSuccess
                      ? [Colors.deepPurple, Colors.deepPurple]
                      : [Colors.red.shade600, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isSuccess ? Colors.deepPurple : Colors.red)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
