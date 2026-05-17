import 'package:flutter/material.dart';

class MesclaBrandLogo extends StatelessWidget {
  final double width;

  const MesclaBrandLogo({super.key, this.width = 260});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/mescla_logo_lockup.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'MesclaInvest',
    );
  }
}
