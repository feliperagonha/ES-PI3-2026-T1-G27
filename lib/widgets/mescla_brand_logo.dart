import 'package:flutter/material.dart';

class MesclaBrandLogo extends StatelessWidget {
  final double width;
  final String assetPath;

  const MesclaBrandLogo({
    super.key,
    this.width = 260,
    this.assetPath = 'assets/branding/mescla_logo_lockup.png',
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'MesclaInvest',
    );
  }
}
