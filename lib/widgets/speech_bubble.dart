import 'package:flutter/material.dart';

class SpeechBubble extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final TextAlign textAlign;
  final TextStyle? textStyle;
  final double borderRadius;
  final double arrowHeight;
  final double arrowWidth;
  final EdgeInsetsGeometry contentPadding;

  const SpeechBubble({
    Key? key,
    required this.text,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.textColor = Colors.black,
    this.textAlign = TextAlign.left,
    this.textStyle,
    this.borderRadius = 12.0,
    this.arrowHeight = 10.0,
    this.arrowWidth = 15.0,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = textStyle ?? TextStyle(color: textColor, fontSize: 15, height: 1.3);

    return Container(
      padding: EdgeInsets.only(bottom: arrowHeight),
      child: CustomPaint(
        painter: _SpeechBubblePainter(
          bubbleColor: backgroundColor,
          arrowHeight: arrowHeight,
          arrowWidth: arrowWidth,
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: contentPadding,
          child: Text(
            text,
            textAlign: textAlign,
            style: effectiveTextStyle,
          ),
        ),
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  final Color bubbleColor;
  final double arrowHeight;
  final double arrowWidth;
  final double borderRadius;

  _SpeechBubblePainter({
    required this.bubbleColor,
    required this.arrowHeight,
    required this.arrowWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final RRect bubbleBody = RRect.fromLTRBAndCorners(
      0,
      0,
      size.width,
      size.height,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    final Path arrowPath = Path();
    double arrowStartPointX = borderRadius;

    arrowPath.moveTo(arrowStartPointX, size.height);
    arrowPath.lineTo(arrowStartPointX + (arrowWidth / 2), size.height + arrowHeight);
    arrowPath.lineTo(arrowStartPointX + arrowWidth, size.height);
    arrowPath.close();

    canvas.drawRRect(bubbleBody, paint);
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) {
    return oldDelegate.bubbleColor != bubbleColor ||
        oldDelegate.arrowHeight != arrowHeight ||
        oldDelegate.arrowWidth != arrowWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
