import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_integrador3_g27/screens/authentication/login_page.dart';

void main() {
  testWidgets('Login page renders the primary authentication flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('MESCLA\nINVEST'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Esqueceu sua senha?'), findsOneWidget);
    expect(find.text('Criar uma conta agora'), findsOneWidget);
  });
}
