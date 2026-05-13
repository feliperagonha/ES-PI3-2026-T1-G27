// Felipe Ragonha
// RA: 24023900

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'authentication/login_page.dart';
import 'two_factor_verify_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _functions = FirebaseFunctions.instanceFor(region: 'southamerica-east1');
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;

  // Dados do usuário
  String _name = '';
  String _phone = '';
  String _email = '';
  String _cpf = '';
  bool _twoFactorEnabled = false;

  // Controllers de edição
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Carregar dados do Firestore 

  Future<void> _carregarDados() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      setState(() {
        _name = data['name'] ?? '';
        _phone = data['phone'] ?? '';
        _email = data['email'] ?? _auth.currentUser?.email ?? '';
        _cpf = data['cpf'] ?? '';
        _twoFactorEnabled = data['twoFactorEnabled'] ?? false;
        _nameController.text = _name;
        _phoneController.text = _phone;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack('Erro ao carregar dados.');
    }
  }

  // Salvar edição

  Future<void> _salvar() async {
    final nome = _nameController.text.trim();
    final telefone = _phoneController.text.trim();

    if (nome.isEmpty) {
      _snack('Nome não pode ser vazio.');
      return;
    }

    setState(() => _saving = true);
    try {
      final callable = _functions.httpsCallable('updateProfile');
      await callable.call({'name': nome, 'phone': telefone});

      setState(() {
        _name = nome;
        _phone = telefone;
        _editando = false;
      });
      _snack('Perfil atualizado com sucesso!', success: true);
    } on FirebaseFunctionsException catch (e) {
      _snack('Erro: ${e.message ?? e.code}');
    } catch (e) {
      _snack('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Desativar ou Ativar o dois fatores (2fa)

  Future<void> _toggle2FA(bool ativar) async {
    if (ativar) {
      // Envia código e abre tela de verificação
      setState(() => _saving = true);
      try {
        final callable = _functions.httpsCallable('sendTwoFactorCode');
        await callable.call({});
        if (!mounted) return;

        // Navega para tela de verificação do código
        final confirmado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const TwoFactorVerifyScreen(ativando: true),
          ),
        );

        if (confirmado == true) {
          setState(() => _twoFactorEnabled = true);
          _snack('2FA ativado com sucesso!', success: true);
        }
      } on FirebaseFunctionsException catch (e) {
        _snack('Erro: ${e.message ?? e.code}');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } else {
      // Desativar 2FA: pede confirmação
      final confirmar = await _showDialog(
        titulo: 'Desativar 2FA',
        mensagem: 'Tem certeza que deseja desativar a autenticação em dois fatores?',
        botaoConfirmar: 'Desativar',
        corBotao: Colors.orange,
      );

      if (confirmar != true) return;

      setState(() => _saving = true);
      try {
        final callable = _functions.httpsCallable('disableTwoFactor');
        await callable.call({});
        setState(() => _twoFactorEnabled = false);
        _snack('2FA desativado.', success: true);
      } on FirebaseFunctionsException catch (e) {
        _snack('Erro: ${e.message ?? e.code}');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  // Deletar conta

  Future<void> _deletarConta() async {
    final confirmar = await _showDialog(
      titulo: 'Deletar conta',
      mensagem:
          'Esta ação é irreversível. Todos os seus dados serão apagados permanentemente.',
      botaoConfirmar: 'Deletar',
      corBotao: Colors.red,
    );

    if (confirmar != true) return;

    setState(() => _deleting = true);
    try {
      final callable = _functions.httpsCallable('deleteAccount');
      await callable.call({});
      await _auth.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } on FirebaseFunctionsException catch (e) {
      _snack('Erro: ${e.message ?? e.code}');
    } catch (e) {
      _snack('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // Logout

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // Helpers

  Future<bool?> _showDialog({
    required String titulo,
    required String mensagem,
    required String botaoConfirmar,
    required Color corBotao,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: corBotao,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(botaoConfirmar,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF6A4CFF) : null,
    ));
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3A1C71),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
              onPressed: () => setState(() => _editando = true),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A4CFF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ──────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFF6A4CFF),
                          child: Text(
                            _name.isNotEmpty
                                ? _name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Dados do usuário
                  _SectionTitle('Informações'),
                  const SizedBox(height: 12),

                  _editando ? _buildFormEdicao() : _buildDadosVisuais(),

                  if (_editando) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _editando = false;
                              _nameController.text = _name;
                              _phoneController.text = _phone;
                            }),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF6A4CFF)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cancelar',
                                style:
                                    TextStyle(color: Color(0xFF6A4CFF))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _salvar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A4CFF),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Text('Salvar',
                                    style:
                                        TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Segurança / 2FA
                  _SectionTitle('Segurança'),
                  const SizedBox(height: 12),
                  _Card(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _twoFactorEnabled
                                ? const Color(0xFFEDE7FF)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: _twoFactorEnabled
                                ? const Color(0xFF6A4CFF)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Autenticação em 2 fatores',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                _twoFactorEnabled
                                    ? 'Ativado — código por email'
                                    : 'Desativado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _twoFactorEnabled
                                      ? const Color(0xFF6A4CFF)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF6A4CFF)),
                              )
                            : Switch(
                                value: _twoFactorEnabled,
                                activeColor: const Color(0xFF6A4CFF),
                                onChanged: _toggle2FA,
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // CRUD
                  _SectionTitle('Conta'),
                  const SizedBox(height: 12),

                  // Sair
                  _ActionButton(
                    icon: Icons.logout_rounded,
                    label: 'Sair da conta',
                    color: const Color(0xFF3A1C71),
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 10),

                  // Deletar
                  _ActionButton(
                    icon: Icons.delete_forever_rounded,
                    label: 'Deletar conta',
                    color: Colors.red,
                    onPressed: _deleting ? null : _deletarConta,
                    loading: _deleting,
                  ),
                ],
              ),
            ),
    );
  }

  // Dados (read-only)
  Widget _buildDadosVisuais() {
    return _Card(
      child: Column(
        children: [
          _InfoRow(Icons.person_outline_rounded, 'Nome', _name),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _InfoRow(Icons.email_outlined, 'Email', _email),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _InfoRow(Icons.phone_outlined, 'Telefone',
              _phone.isNotEmpty ? _phone : '—'),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _InfoRow(Icons.badge_outlined, 'CPF',
              _cpf.isNotEmpty ? _cpf : '—'),
        ],
      ),
    );
  }

  // Form de edição

  Widget _buildFormEdicao() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Nome'),
          const SizedBox(height: 6),
          _EditField(controller: _nameController, hint: 'Seu nome'),
          const SizedBox(height: 16),
          _FieldLabel('Telefone'),
          const SizedBox(height: 6),
          _EditField(
            controller: _phoneController,
            hint: '(xx) xxxxx-xxxx',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          const Text(
            'Email e CPF não podem ser alterados.',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

//  WIDGETS INTERNOS

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF6A4CFF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF6A4CFF),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E)));
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _EditField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.black38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFF6A4CFF), width: 1.5),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool loading;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.loading = false,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 18, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
