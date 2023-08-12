import 'package:flutter/material.dart';

class FractionalRangeClipperVertical extends CustomClipper<Path> {
  final double begin;
  final double end;

  FractionalRangeClipperVertical({required this.begin, required this.end});

  @override
  Path getClip(Size size) {
    final path = Path();
    final absoluteBegin = size.height * (1 - end); // Calculate the inverted value
    final absoluteEnd = size.height * (1 - begin); // Calculate the inverted value
    path.lineTo(0, absoluteBegin); // Start from bottom-left corner
    path.lineTo(size.width, absoluteBegin); // Move to bottom-right corner
    path.lineTo(size.width, absoluteEnd); // Move to top-right corner
    path.lineTo(0, absoluteEnd); // Move to top-left corner
    path.close(); // Close the path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}