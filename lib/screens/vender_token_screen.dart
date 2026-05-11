// Felipe Ragonha
// RA: 24023900

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/startup.dart';
import '../repositories/startup_repository.dart';
import '../services/mercado_service.dart';

class VenderTokenScreen extends StatefulWidget {
  final String userId;
  const VenderTokenScreen({super.key, required this.userId});

  @override
  State<VenderTokenScreen> createState() => _VenderTokenScreenState();
}

class _VenderTokenScreenState extends State<VenderTokenScreen> {
  final StartupRepository _startupRepo = StartupRepository();
  final MercadoService _mercadoService = MercadoService();
  final _firestore = FirebaseFirestore.instance;

  final _precoController = TextEditingController();
  final _quantidadeController = TextEditingController();

  Startup? _startupSelecionada;
  int _saldoDisponivel = 0;
  bool _enviando = false;
  bool _carregandoSaldo = false;

  @override
  void dispose() {
    _precoController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  // Busca saldo de tokens do usuário para a startup selecionada
  Future<void> _carregarSaldo(String startupId) async {
    _carregandoSaldo = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      final investDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('investimentos')
          .doc(startupId)
          .get();

      final totalShares = investDoc.exists
          ? (investDoc.data()?['totalShares'] ?? 0) as int
          : 0;

      // Desconta tokens já anunciados
      final ofertasSnap = await _firestore
          .collection('mercado')
          .where('vendedorId', isEqualTo: uid)
          .where('startupId', isEqualTo: startupId)
          .get();

      final tokensAnunciados = ofertasSnap.docs
          .fold<int>(0, (acc, doc) => acc + ((doc.data()['quantidade'] ?? 0) as int));

      setState(() => _saldoDisponivel = totalShares - tokensAnunciados);
    } catch (e) {
      setState(() => _saldoDisponivel = 0);
    } finally {
      if (mounted) setState(() => _carregandoSaldo = false);
    }
  }

  Future<void> _confirmarVenda() async {
    if (_startupSelecionada == null) {
      _snack('Selecione uma startup.');
      return;
    }

    final preco = double.tryParse(
        _precoController.text.trim().replaceAll(',', '.'));
    final quantidade = int.tryParse(_quantidadeController.text.trim());

    if (preco == null || preco <= 0) {
      _snack('Digite um preço válido.');
      return;
    }
    if (quantidade == null || quantidade <= 0) {
      _snack('Digite uma quantidade válida.');
      return;
    }
    if (quantidade > _saldoDisponivel) {
      _snack('Quantidade maior que seu saldo disponível ($_saldoDisponivel tokens).');
      return;
    }

    final startup = _startupSelecionada!;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar venda'),
        content: Text(
          'Colocar $quantidade token${quantidade > 1 ? 's' : ''} '
          'de ${startup.name} à venda por R\$ ${preco.toStringAsFixed(2)} cada?\n\n'
          'Total: R\$ ${(preco * quantidade).toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A4CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _enviando = true);
    try {
      await _mercadoService.criarOferta(
        startupId: startup.id,
        startupName: startup.name,
        startupSector: startup.sector,
        startupStage: startup.stage,
        quantidade: quantidade,
        preco: preco,
      );
      if (!mounted) return;
      _snack('Token colocado à venda com sucesso!', success: true);
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      _snack(e.message ?? 'Erro: ${e.code}');
    } catch (e) {
      _snack('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
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
          'Vender Token',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selecionar Startup ────────────────────────
            _SectionLabel('Selecionar Startup'),
            const SizedBox(height: 10),
            StreamBuilder<List<Startup>>(
              stream: _startupRepo.getStartups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6A4CFF)),
                  );
                }

                final startups = snapshot.data ?? [];

                if (startups.isEmpty) {
                  return const Text('Nenhuma startup disponível.',
                      style: TextStyle(color: Color(0xFF6B7280)));
                }

                return Column(
                  children: startups.map((s) {
                    final selecionada = _startupSelecionada?.id == s.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _startupSelecionada = s;
                          _quantidadeController.clear();
                          _precoController.clear();
                        });
                        _carregarSaldo(s.id);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selecionada
                                ? const Color(0xFF6A4CFF)
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE7FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  s.name.length >= 2
                                      ? s.name.substring(0, 2).toUpperCase()
                                      : s.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF6A4CFF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    '${s.sector} · ${s.stage}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selecionada)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF6A4CFF)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // ── Saldo disponível ──────────────────────────
            if (_startupSelecionada != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _saldoDisponivel > 0
                      ? const Color(0xFFEDE7FF)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.token_rounded,
                      size: 16,
                      color: _saldoDisponivel > 0
                          ? const Color(0xFF6A4CFF)
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                            _saldoDisponivel > 0
                                ? 'Disponível para venda: $_saldoDisponivel token${_saldoDisponivel != 1 ? 's' : ''}'
                                : 'Você não possui tokens disponíveis desta startup.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _saldoDisponivel > 0
                                  ? const Color(0xFF6A4CFF)
                                  : Colors.red,
                            ),
                          ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Quantidade ────────────────────────────────
            _SectionLabel('Quantidade de tokens'),
            const SizedBox(height: 10),
            _InputField(
              controller: _quantidadeController,
              hint: _saldoDisponivel > 0
                  ? 'Máx: $_saldoDisponivel'
                  : 'Ex: 10',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              enabled: _startupSelecionada != null && _saldoDisponivel > 0,
            ),

            const SizedBox(height: 20),

            // ── Preço ─────────────────────────────────────
            _SectionLabel('Preço por token (R\$)'),
            const SizedBox(height: 10),
            _InputField(
              controller: _precoController,
              hint: 'Ex: 15.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              enabled: _startupSelecionada != null && _saldoDisponivel > 0,
            ),

            // Preview do total
            Builder(builder: (context) {
              final preco = double.tryParse(
                  _precoController.text.replaceAll(',', '.'));
              final qtd = int.tryParse(_quantidadeController.text);
              if (preco != null && qtd != null && preco > 0 && qtd > 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total da oferta',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF6B7280))),
                        Text(
                          'R\$ ${(preco * qtd).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6A4CFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: 32),

            // ── Botão confirmar ───────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_enviando ||
                        _startupSelecionada == null ||
                        _saldoDisponivel <= 0)
                    ? null
                    : _confirmarVenda,
                icon: const Icon(Icons.sell_rounded,
                    size: 18, color: Colors.white),
                label: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Colocar à venda',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A4CFF),
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E)));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF6A4CFF), width: 1.5),
        ),
      ),
    );
  }
}
