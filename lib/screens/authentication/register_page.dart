// Guilherme Marras - 24027681
// Juliano Perusso -

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../widgets/mescla_brand_logo.dart';

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

  bool get _hasMinLength => passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(passwordController.text);
  bool get _hasSpecialChar => RegExp(
    r'[!@#\$%^&*(),.?":{}|<>_\-+=;\/\\\[\]~`]',
  ).hasMatch(passwordController.text);

  bool get _isPasswordValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar;

  String get _passwordRuleMessage =>
      'Use 8 caracteres, letra maiuscula, minuscula, numero e caractere especial.';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      ).httpsCallable('registerUser');

      await callable.call({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'cpf': cpfMask.getUnmaskedText(),
        'phone': phoneMask.getUnmaskedText(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso.')),
      );

      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      String mensagem = 'Erro ao cadastrar usuário.';

      if (e.code == 'already-exists') {
        mensagem = 'Este e-mail já está em uso.';
      } else if (e.code == 'invalid-argument') {
        mensagem = e.message ?? 'Dados inválidos.';
      } else {
        mensagem =
            'Erro da Function: ${e.code} - ${e.message ?? 'sem mensagem'}';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
          inputFormatters: formatters, // Aplica a máscara se houver
          validator: validator, // Executa a validação do campo
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
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

  Widget passwordRequirement(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: valid ? const Color(0xFFB8FFB8) : Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: valid ? const Color(0xFFB8FFB8) : Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget passwordRequirements() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sua senha deve conter:',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 6),
          passwordRequirement('Pelo menos 8 caracteres', _hasMinLength),
          passwordRequirement('Uma letra maiuscula', _hasUppercase),
          passwordRequirement('Uma letra minuscula', _hasLowercase),
          passwordRequirement('Um numero', _hasNumber),
          passwordRequirement('Um caractere especial', _hasSpecialChar),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A1C71), Color(0xFF6A4CFF), Color(0xFF3A1C71)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            // NOVA ALTERAÇÃO: Envolvemos a Column com o Form e passamos a nossa _formKey
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const MesclaBrandLogo(
                    width: 168,
                    assetPath: 'assets/branding/mescla_mark.png',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Criar conta',
                    style: TextStyle(
                      color: Colors
                          .white, // Ajustei para branco para melhor leitura
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
                      if (value == null || value.isEmpty) {
                        return 'Preencha seu email';
                      }
                      // RegEx simples para verificar formato de email (algo@algo.com)
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Digite um email válido';
                      }
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
                    onChanged: (_) => setState(() {}),
                    onToggleVisibility: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Preencha sua senha';
                      }
                      if (!_isPasswordValid) return _passwordRuleMessage;
                      return null;
                    },
                  ),
                  passwordRequirements(),
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
                      if (value == null || value.isEmpty) {
                        return 'Confirme sua senha';
                      }
                      if (value != passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 6),

                  SizedBox(
                    width: 160,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: loading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A4CFF),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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

                  const SizedBox(height: 12),

                  SizedBox(
                    width: 160,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A4CFF),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Voltar',
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
