import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Necessário para aceitar formatadores (máscaras) no campo
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // O pacote que acabamos de instalar

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // NOVA ALTERAÇÃO: Chave global para controlar o formulário e disparar os erros em vermelho
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final cpfController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  // NOVA ALTERAÇÃO: Configurando a máscara do CPF (só aceita números no lugar do #)
  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // NOVA ALTERAÇÃO: Configurando a máscara do Telefone
  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

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
    // NOVA ALTERAÇÃO: Em vez de vários "if", checamos o formulário todo de uma vez
    if (!_formKey.currentState!.validate()) {
      return; // Se tiver erro em qualquer campo, para aqui
    }

    setState(() => loading = true);

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // NOVA ALTERAÇÃO: Usamos o 'getUnmaskedText' para salvar no banco o CPF e o Telefone APENAS com números, sem os traços e pontos.
      await firestore.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'cpf': cpfMask.getUnmaskedText(),
        'phone': phoneMask.getUnmaskedText(),
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

  // NOVA ALTERAÇÃO: O método 'field' agora usa TextFormField, aceita máscaras e funções de validação
  Widget field(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>?
    formatters, // Propriedade para receber as máscaras
    String? Function(String?)?
    validator, // Propriedade para receber a regra de erro do campo
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          // Trocado para poder usar validação
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: formatters, // Aplica a máscara se houver
          validator: validator, // Executa a validação do campo
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            errorStyle: const TextStyle(
              color: Colors.orangeAccent,
            ), // Deixei laranja para destacar no fundo roxo
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
            // NOVA ALTERAÇÃO: Envolvemos a Column com o Form e passamos a nossa _formKey
            child: Form(
              key: _formKey,
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
                      color: Colors
                          .white, // Ajustei para branco para melhor leitura
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 26),

                  field(
                    'Nome Completo',
                    nameController,
                    hint: 'Nome Completo',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Preencha seu nome'
                        : null,
                  ),
                  field(
                    'Email',
                    emailController,
                    hint: 'Entre com seu email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Preencha seu email';
                      // RegEx simples para verificar formato de email (algo@algo.com)
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return 'Digite um email válido';
                      return null;
                    },
                  ),
                  field(
                    'CPF',
                    cpfController,
                    hint: '123.456.789-10',
                    keyboardType: TextInputType.number,
                    formatters: [cpfMask], // Passando a máscara do CPF aqui!
                    validator: (value) => value == null || value.isEmpty
                        ? 'Preencha seu CPF'
                        : null,
                  ),
                  field(
                    'Telefone com DDD',
                    phoneController,
                    hint: '(xx) xxxxx-xxxx',
                    keyboardType: TextInputType.phone,
                    formatters: [
                      phoneMask,
                    ], // Passando a máscara do Telefone aqui!
                    validator: (value) => value == null || value.isEmpty
                        ? 'Preencha seu telefone'
                        : null,
                  ),
                  field(
                    'Senha',
                    passwordController,
                    isPassword: true,
                    obscureText: obscurePassword,
                    onToggleVisibility: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Preencha sua senha';
                      if (value.length < 6) return 'Mínimo de 6 caracteres';
                      return null;
                    },
                  ),
                  field(
                    'Confirme sua Senha',
                    confirmController,
                    isPassword: true,
                    obscureText: obscureConfirmPassword,
                    onToggleVisibility: () {
                      setState(
                        () => obscureConfirmPassword = !obscureConfirmPassword,
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Confirme sua senha';
                      if (value != passwordController.text)
                        return 'As senhas não coincidem';
                      return null;
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
      ),
    );
  }
}
