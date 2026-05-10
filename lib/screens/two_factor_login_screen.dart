// Felipe Ragonha
// RA: 24023900

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'catalogo_startups_screen.dart';

class TwoFactorLoginScreen extends StatefulWidget {
  final String uid;
  const TwoFactorLoginScreen({super.key, required this.uid});

  @override
  State<TwoFactorLoginScreen> createState() => _TwoFactorLoginScreenState();
}

class _TwoFactorLoginScreenState extends State<TwoFactorLoginScreen> {
  final _functions =
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _verificando = false;
  bool _reenviando = false;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _codigoCompleto =>
      _controllers.map((c) => c.text).join();

  Future<void> _verificar() async {
    if (_codigoCompleto.length < 6) {
      _snack('Digite o código completo de 6 dígitos.');
      return;
    }

    setState(() => _verificando = true);
    try {
      // Verifica o código — ativando: false pois é login, não ativação
      final callable = _functions.httpsCallable('verifyTwoFactorCode');
      final result = await callable.call({
        'code': _codigoCompleto,
        'ativando': false,
      });

      final data = result.data as Map<String, dynamic>;
      final token = data['token'] as String?;

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // Loga com o custom token retornado
        await FirebaseAuth.instance.signInWithCustomToken(token);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const CatalogoStartupsScreen()),
          (route) => false,
        );
      } else {
        _snack('Erro ao obter token de acesso.');
      }
    } on FirebaseFunctionsException catch (e) {
      _snack(e.message ?? 'Código inválido ou expirado.');
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } catch (e) {
      _snack('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    try {
      final callable = _functions.httpsCallable('resendTwoFactorCode');
      await callable.call({'uid': widget.uid});
      _snack('Novo código enviado para seu email!', success: true);
    } on FirebaseFunctionsException catch (e) {
      _snack(e.message ?? 'Erro ao reenviar código.');
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF6A4CFF) : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A1C71),
        foregroundColor: Colors.white,
        title: const Text(
          'Verificação em 2 Fatores',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: Color(0xFF6A4CFF),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Verificação necessária',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enviamos um código de 6 dígitos\npara o seu email cadastrado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),

            const SizedBox(height: 36),

            // Campos de dígito
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 46,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _controllers[index].text.isNotEmpty
                          ? const Color(0xFF6A4CFF)
                          : const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => _onDigitEntered(index, value),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _verificando ? null : _verificar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A4CFF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _verificando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Confirmar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: _reenviando ? null : _reenviar,
              child: _reenviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF6A4CFF)),
                    )
                  : const Text(
                      'Reenviar código',
                      style: TextStyle(
                        color: Color(0xFF6A4CFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
