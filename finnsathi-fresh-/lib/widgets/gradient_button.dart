import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Gradient gradient;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const GradientButton({
    Key? key,
    required this.onPressed,
    required this.child,
    required this.gradient,
    this.width = double.infinity,
    this.height = 50.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
