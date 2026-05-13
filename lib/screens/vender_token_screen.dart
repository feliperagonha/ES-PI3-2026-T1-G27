//Felipe Ragonha
//RA: 24023900

// Juliano Perusso
// RA: 24023434

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/startup.dart';
import '../repositories/startup_repository.dart';
import '../services/mercado_service.dart';

class VenderTokenScreen extends StatefulWidget {
  final String userId;

  const VenderTokenScreen({
    super.key,
    required this.userId,
  });

  @override
  State<VenderTokenScreen> createState() => _VenderTokenScreenState();
}

class _VenderTokenScreenState extends State<VenderTokenScreen> {
  final StartupRepository _startupRepo = StartupRepository();
  final MercadoService _mercadoService = MercadoService();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();

  late Future<List<Startup>> _startupsFuture;

  Startup? _startupSelecionada;
  int _saldoDisponivel = 0;

  bool _enviando = false;
  bool _carregandoSaldo = false;

  @override
  void initState() {
    super.initState();
    _startupsFuture = _startupRepo.listStartups();
  }

  @override
  void dispose() {
    _precoController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  Future<void> _carregarSaldo(String startupId) async {
    setState(() {
      _carregandoSaldo = true;
      _saldoDisponivel = 0;
    });

    try {
      final callable = _functions.httpsCallable('listInvestorPositions');

      final result = await callable.call();

      final response = Map<String, dynamic>.from(result.data);

      final positions = List<Map<String, dynamic>>.from(
        (response['data'] as List).map(
              (item) => Map<String, dynamic>.from(item),
        ),
      );

      final position = positions.where((item) {
        return item['startupId'] == startupId;
      }).toList();

      if (position.isEmpty) {
        setState(() {
          _saldoDisponivel = 0;
        });
        return;
      }

      final availableQuantity =
      (position.first['availableQuantity'] ?? 0).toInt();

      setState(() {
        _saldoDisponivel = availableQuantity;
      });
    } on FirebaseFunctionsException catch (e) {
      _snack(e.message ?? 'Erro ao carregar saldo: ${e.code}');
      setState(() {
        _saldoDisponivel = 0;
      });
    } catch (e) {
      _snack('Erro inesperado ao carregar saldo: $e');
      setState(() {
        _saldoDisponivel = 0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregandoSaldo = false;
        });
      }
    }
  }

  Future<void> _confirmarVenda() async {
    if (_startupSelecionada == null) {
      _snack('Selecione uma startup.');
      return;
    }

    final preco = double.tryParse(
      _precoController.text.trim().replaceAll(',', '.'),
    );

    final quantidade = int.tryParse(
      _quantidadeController.text.trim(),
    );

    if (preco == null || preco <= 0) {
      _snack('Digite um preço válido.');
      return;
    }

    if (quantidade == null || quantidade <= 0) {
      _snack('Digite uma quantidade válida.');
      return;
    }

    if (quantidade > _saldoDisponivel) {
      _snack(
        'Quantidade maior que seu saldo disponível '
            '($_saldoDisponivel tokens).',
      );
      return;
    }

    final startup = _startupSelecionada!;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _enviando = true;
    });

    try {
      await _mercadoService.criarOferta(
        startupId: startup.id,
        startupName: startup.name,
        sector: startup.sector,
        stage: startup.stage,
        quantidade: quantidade,
        preco: preco,
      );

      if (!mounted) return;

      _snack(
        'Token colocado à venda com sucesso!',
        success: true,
      );

      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      _snack(e.message ?? 'Erro: ${e.code}');
    } catch (e) {
      _snack('Erro inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF6A4CFF) : null,
      ),
    );
  }

  Widget _buildStartupList() {
    return FutureBuilder<List<Startup>>(
      future: _startupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFF6A4CFF),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Erro ao carregar startups: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final startups = snapshot.data ?? [];

        if (startups.isEmpty) {
          return const Text(
            'Nenhuma startup disponível.',
            style: TextStyle(color: Color(0xFF6B7280)),
          );
        }

        return Column(
          children: startups.map((startup) {
            final selecionada = _startupSelecionada?.id == startup.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _startupSelecionada = startup;
                  _quantidadeController.clear();
                  _precoController.clear();
                  _saldoDisponivel = 0;
                });

                _carregarSaldo(startup.id);
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
                      color: Colors.black.withValues(alpha: 0.04),
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
                          startup.name.length >= 2
                              ? startup.name.substring(0, 2).toUpperCase()
                              : startup.name.toUpperCase(),
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
                            startup.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            '${startup.sector} · ${startup.stage}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selecionada)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF6A4CFF),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSaldoDisponivel() {
    if (_startupSelecionada == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _saldoDisponivel > 0
                ? const Color(0xFFEDE7FF)
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _carregandoSaldo
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6A4CFF),
                ),
              )
                  : Icon(
                Icons.token_rounded,
                size: 16,
                color: _saldoDisponivel > 0
                    ? const Color(0xFF6A4CFF)
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _carregandoSaldo
                      ? 'Carregando saldo disponível...'
                      : _saldoDisponivel > 0
                      ? 'Disponível para venda: $_saldoDisponivel token${_saldoDisponivel != 1 ? 's' : ''}'
                      : 'Você não possui tokens disponíveis desta startup.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _saldoDisponivel > 0
                        ? const Color(0xFF6A4CFF)
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTotalPreview() {
    final preco = double.tryParse(
      _precoController.text.replaceAll(',', '.'),
    );

    final quantidade = int.tryParse(
      _quantidadeController.text,
    );

    if (preco == null || quantidade == null || preco <= 0 || quantidade <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Total da oferta',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            Text(
              'R\$ ${(preco * quantidade).toStringAsFixed(2)}',
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

  @override
  Widget build(BuildContext context) {
    final podeEnviar = !_enviando &&
        !_carregandoSaldo &&
        _startupSelecionada != null &&
        _saldoDisponivel > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A1C71),
        foregroundColor: Colors.white,
        title: const Text(
          'Vender Token',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Selecionar Startup'),
            const SizedBox(height: 10),
            _buildStartupList(),

            _buildSaldoDisponivel(),

            const _SectionLabel('Quantidade de tokens'),
            const SizedBox(height: 10),
            _InputField(
              controller: _quantidadeController,
              hint: _saldoDisponivel > 0 ? 'Máx: $_saldoDisponivel' : 'Ex: 10',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              enabled: _startupSelecionada != null && _saldoDisponivel > 0,
            ),

            const SizedBox(height: 20),

            const _SectionLabel('Preço por token (R\$)'),
            const SizedBox(height: 10),
            _InputField(
              controller: _precoController,
              hint: 'Ex: 15.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              enabled: _startupSelecionada != null && _saldoDisponivel > 0,
            ),

            _buildTotalPreview(),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: podeEnviar ? _confirmarVenda : null,
                icon: const Icon(
                  Icons.sell_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: _enviando
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
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
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    );
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
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontSize: 14,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF6A4CFF),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}