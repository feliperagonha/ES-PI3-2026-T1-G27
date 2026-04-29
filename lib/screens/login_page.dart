import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'catalogo_startups_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // NOVA ALTERAÇÃO: Chave global para validar o formulário de login
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscure = true;
  bool loading = false;

  final auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    // NOVA ALTERAÇÃO: Validação integrada dos campos
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CatalogoStartupsScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao fazer login.';

      if (e.code == 'user-not-found') {
        mensagem = 'Usuário não encontrado.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensagem = 'Email ou senha inválidos.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Email inválido.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digite seu email no campo acima para recuperar a senha.',
          ),
        ),
      );
      return;
    }

    try {
      await auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de recuperação enviado com sucesso.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível enviar o email de recuperação.';

      if (e.code == 'invalid-email') {
        mensagem = 'Email inválido.';
      } else if (e.code == 'user-not-found') {
        mensagem = 'Usuário não encontrado.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3A1C71), Color(0xFF6A4CFF), Color(0xFF3A1C71)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            // NOVA ALTERAÇÃO: Formulário envolvendo os campos
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'MESCLA\nINVEST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7C4DFF),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white, // Ajustado para branco
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // NOVA ALTERAÇÃO: TextFormField para o Email
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Preencha seu email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return 'Email inválido';
                      return null;
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Entre com seu email',
                      hintStyle: const TextStyle(fontSize: 12),
                      errorStyle: const TextStyle(color: Colors.orangeAccent),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Senha',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // NOVA ALTERAÇÃO: TextFormField para a Senha
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscure,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Preencha sua senha';
                      return null;
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: '********',
                      hintStyle: const TextStyle(fontSize: 12),
                      errorStyle: const TextStyle(color: Colors.orangeAccent),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: resetPassword,
                      child: const Text(
                        'Esqueceu sua senha?',
                        style: TextStyle(
                          color: Color(0xFFB8A7FF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2DBF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'PRÓXIMO',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white38)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Ou',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white38)),
                    ],
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      'Criar uma conta agora',
                      style: TextStyle(
                        color: Colors.white,
                      ), // Ajustado para dar contraste no fundo
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
