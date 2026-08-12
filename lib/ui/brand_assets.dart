import 'package:flutter/material.dart';

class SaydianBrandLockup extends StatelessWidget {
  const SaydianBrandLockup({super.key, this.width = 190});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/saidian-brand-lockup.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: '赛电',
    );
  }
}

class SaydianBrandMark extends StatelessWidget {
  const SaydianBrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/saidian-brand-mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: '赛电',
    );
  }
}
