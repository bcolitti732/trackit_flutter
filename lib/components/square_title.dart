import 'package:flutter/material.dart';

class SquareTitle extends StatelessWidget {
  final String imagePath;
  final double size;

  const SquareTitle({
    super.key,
    required this.imagePath,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[100]!),
        borderRadius: BorderRadius.circular(16),
        color: Colors.blue[50],
      ),
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
      ),
    );
  }
}