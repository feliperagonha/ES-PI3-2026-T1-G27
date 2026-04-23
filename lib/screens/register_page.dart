import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final cpfController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool loading = false;

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    cpfController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final cpf = cpfController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        cpf.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senhas não coincidem.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'cpf': cpf,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso.')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao cadastrar usuário.';

      if (e.code == 'email-already-in-use') {
        mensagem = 'Este email já está em uso.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Email inválido.';
      } else if (e.code == 'weak-password') {
        mensagem = 'Senha muito fraca.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget field(
      String label,
      TextEditingController controller, {
        bool isPassword = false,
        bool obscureText = false,
        VoidCallback? onToggleVisibility,
        String? hint,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
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
            child: Column(
              children: [
                const SizedBox(height: 8),
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
                  'Registro',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 26),

                field(
                  'Nome Completo',
                  nameController,
                  hint: 'Nome Completo',
                ),
                field(
                  'Email',
                  emailController,
                  hint: 'Entre com seu email',
                  keyboardType: TextInputType.emailAddress,
                ),
                field(
                  'CPF',
                  cpfController,
                  hint: '123.456.789-10',
                  keyboardType: TextInputType.number,
                ),
                field(
                  'Telefone com DDD',
                  phoneController,
                  hint: '(xx) xxxxx-xxxx',
                  keyboardType: TextInputType.phone,
                ),
                field(
                  'Senha',
                  passwordController,
                  isPassword: true,
                  obscureText: obscurePassword,
                  onToggleVisibility: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                ),
                field(
                  'Confirme sua Senha',
                  confirmController,
                  isPassword: true,
                  obscureText: obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                  },
                ),

                const SizedBox(height: 6),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: loading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A4CFF),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}