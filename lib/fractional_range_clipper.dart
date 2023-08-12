import 'package:flutter/material.dart';

class FractionalRangeClipper extends CustomClipper<Path> {
  final double begin;
  final double end;

  FractionalRangeClipper({required this.begin, required this.end});

  @override
  Path getClip(Size size) {
    final path = Path();
    final absoluteBegin = size.width * begin;
    final absoluteEnd = size.width * end;
    path.lineTo(absoluteBegin, 0);
    path.lineTo(absoluteBegin, size.height);
    path.lineTo(absoluteEnd, size.height);
    path.lineTo(absoluteEnd, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}