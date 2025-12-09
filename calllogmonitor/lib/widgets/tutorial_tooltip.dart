import 'dart:async';
import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';

class TutorialTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final String tutorialKey;
  final bool showOnFirstTap;
  final VoidCallback? onTooltipShown;

  const TutorialTooltip({
    Key? key,
    required this.child,
    required this.message,
    required this.tutorialKey,
    this.showOnFirstTap = true,
    this.onTooltipShown,
  }) : super(key: key);

  @override
  State<TutorialTooltip> createState() => _TutorialTooltipState();
}

class _TutorialTooltipState extends State<TutorialTooltip> {
  bool _showTooltip = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (!widget.showOnFirstTap) {
      _checkAndShowTooltip();
    }
  }

  Future<void> _checkAndShowTooltip() async {
    final shouldShow = !(await TutorialService.isTutorialCompleted(widget.tutorialKey));
    if (shouldShow && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTooltipOverlay();
      });
    }
  }

  void _onTap() {
    if (widget.showOnFirstTap) {
      _checkAndShowTooltipOnTap();
    }
  }

  Future<void> _checkAndShowTooltipOnTap() async {
    final shouldShow = !(await TutorialService.isTutorialCompleted(widget.tutorialKey));
    if (shouldShow && mounted) {
      _showTooltipOverlay();
    }
  }

  void _showTooltipOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        targetOffset: offset,
        targetSize: size,
        message: widget.message,
        onDismiss: _hideTooltipOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    widget.onTooltipShown?.call();
    TutorialService.markTutorialCompleted(widget.tutorialKey);
  }

  void _hideTooltipOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTooltipOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: widget.child,
    );
  }
}

class _TooltipOverlay extends StatefulWidget {
  final Offset targetOffset;
  final Size targetSize;
  final String message;
  final VoidCallback onDismiss;

  const _TooltipOverlay({
    required this.targetOffset,
    required this.targetSize,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_TooltipOverlay> createState() => _TooltipOverlayState();
}

class _TooltipOverlayState extends State<_TooltipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();

    // Auto-dismiss after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final targetCenter = widget.targetOffset + Offset(widget.targetSize.width / 2, widget.targetSize.height / 2);
    
    // Determine tooltip position
    bool showAbove = targetCenter.dy > screenSize.height / 2;
    double tooltipTop = showAbove 
        ? widget.targetOffset.dy - 80 
        : widget.targetOffset.dy + widget.targetSize.height + 20;

    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        color: Colors.transparent,
        width: screenSize.width,
        height: screenSize.height,
        child: Stack(
          children: [
            // Highlight target
            Positioned(
              left: widget.targetOffset.dx - 8,
              top: widget.targetOffset.dy - 8,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Container(
                    width: widget.targetSize.width + 16,
                    height: widget.targetSize.height + 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(_fadeAnimation.value * 0.8),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(_fadeAnimation.value * 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Tooltip
            Positioned(
              left: 16,
              right: 16,
              top: tooltipTop,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.yellow[300],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _dismiss,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap anywhere to dismiss',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Arrow pointing to target
            if (showAbove)
              Positioned(
                left: targetCenter.dx - 8,
                top: tooltipTop + 60,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: CustomPaint(
                        size: const Size(16, 8),
                        painter: _ArrowPainter(Colors.black87, true),
                      ),
                    );
                  },
                ),
              )
            else
              Positioned(
                left: targetCenter.dx - 8,
                top: tooltipTop - 8,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: CustomPaint(
                        size: const Size(16, 8),
                        painter: _ArrowPainter(Colors.black87, false),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointingDown;

  _ArrowPainter(this.color, this.pointingDown);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
      path.close();
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper widget for first-time button interactions
class FirstTimeButton extends StatelessWidget {
  final Widget child;
  final String tooltipMessage;
  final String tutorialKey;
  final VoidCallback? onPressed;

  const FirstTimeButton({
    Key? key,
    required this.child,
    required this.tooltipMessage,
    required this.tutorialKey,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TutorialTooltip(
      tutorialKey: tutorialKey,
      message: tooltipMessage,
      showOnFirstTap: true,
      child: GestureDetector(
        onTap: onPressed,
        child: child,
      ),
    );
  }
}