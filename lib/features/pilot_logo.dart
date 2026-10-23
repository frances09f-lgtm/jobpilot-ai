import 'package:flutter/material.dart';

/// Original vector artwork, matching the Android launcher. No fonts or network.
class PilotLogo extends StatelessWidget {
  const PilotLogo({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(label: 'JobPilot AI logo', image: true, child: SizedBox(width: size, height: size, child: CustomPaint(painter: _PilotLogoPainter())));
}
class _PilotLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 108, size.height / 108);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 108, 108), const Radius.circular(24)), Paint()..color = const Color(0xFF0A0F1F));
    final plane = Path()..moveTo(24, 48)..lineTo(84, 26)..lineTo(62, 84)..lineTo(50, 61)..close();
    canvas.drawPath(plane, Paint()..shader = const LinearGradient(colors: [Color(0xFF5B8CFF), Color(0xFFA78BFA)]).createShader(const Rect.fromLTWH(24, 26, 60, 58)));
    final fold = Path()..moveTo(50, 61)..lineTo(84, 26)..lineTo(40, 54)..close();
    canvas.drawPath(fold, Paint()..color = const Color(0xFF263863));
    final shine = Path()..moveTo(24, 48)..lineTo(84, 26)..lineTo(40, 54)..close();
    canvas.drawPath(shine, Paint()..color = const Color(0xFF93B4FF));
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
