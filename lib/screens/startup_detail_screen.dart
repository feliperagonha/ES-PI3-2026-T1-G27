//Felipe Ragonha
//RA: 24023900


// Juliano Perusso
// RA: 24023434


import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math' as math;
import '../models/startup.dart';

// Cores
const _purple900 = Color(0xFF3A1C71);
const _purple600 = Color(0xFF6A4CFF);
const _purple100 = Color(0xFFEDE7FF);
const _accent = Color(0xFF6A4CFF);
const _bg = Color(0xFFF1F1F1);
const _surface = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);
const _divider = Color(0xFFE5E7EB);

class StartupDetailScreen extends StatefulWidget {
  final Startup startup;

  const StartupDetailScreen({
    super.key,
    required this.startup,
  });

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  bool _descExpanded = false;
  bool _carregandoMercado = true;
  bool _comprandoTokens = false;

  double? _menorPrecoMercado;

  Startup get s => widget.startup;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _ctrl.forward();
    _carregarMenorPreco();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _carregarMenorPreco() async {
    try {
      final callable = _functions.httpsCallable('listOrders');

      final result = await callable.call({
        'startupId': s.id,
        'onlyOpen': true,
      });

      final response = Map<String, dynamic>.from(result.data);

      final orders = List<Map<String, dynamic>>.from(
        (response['data'] as List).map(
              (item) => Map<String, dynamic>.from(item),
        ),
      );

      double? menorPreco;

      for (final order in orders) {
        final type = order['type']?.toString();
        final preco = NumberParser.toDouble(order['preco']);

        if (type == 'sell' && preco != null) {
          if (menorPreco == null || preco < menorPreco) {
            menorPreco = preco;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _menorPrecoMercado = menorPreco;
        _carregandoMercado = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _menorPrecoMercado = null;
        _carregandoMercado = false;
      });
    }
  }

  Future<void> _comprarTokens() async {
    int quantidadeSelecionada = 0;

    final quantidade = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Investir em ${s.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Preço atual: R\$ ${s.currentPrice.toStringAsFixed(2)}\n'
                          'Tokens disponíveis: ${s.tokensAvailable}',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de tokens',
                        hintText: 'Ex: 10',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final qtd = int.tryParse(value.trim()) ?? 0;

                        setDialogState(() {
                          quantidadeSelecionada = qtd;
                        });
                      },
                    ),
                    if (quantidadeSelecionada > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Total: R\$ ${(quantidadeSelecionada * s.currentPrice).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _purple600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: quantidadeSelecionada <= 0
                      ? null
                      : () {
                    Navigator.of(dialogContext)
                        .pop(quantidadeSelecionada);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple600,
                  ),
                  child: const Text(
                    'Comprar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (quantidade == null) return;

    if (quantidade <= 0) {
      _snack('Digite uma quantidade válida.');
      return;
    }

    if (quantidade > s.tokensAvailable) {
      _snack('Quantidade maior que os tokens disponíveis.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _comprandoTokens = true;
    });

    try {
      final callable = _functions.httpsCallable('buyStartupToken');

      await callable.call({
        'startupId': s.id,
        'quantity': quantidade,
      });

      if (!mounted) return;

      _snack(
        'Compra de $quantidade token${quantidade > 1 ? 's' : ''} realizada com sucesso!',
        success: true,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      _snack(e.message ?? 'Erro: ${e.code}');
    } catch (e) {
      if (!mounted) return;

      _snack('Erro inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _comprandoTokens = false;
        });
      }
    }
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _accent : null,
      ),
    );
  }

  Color _stageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'ideacao':
      case 'ideação':
        return Colors.orange;
      case 'mvp':
        return Colors.blue;
      case 'seed':
        return Colors.purple;
      case 'operacao':
      case 'operação':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(num value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}K';
    }

    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow(),
                    const SizedBox(height: 20),
                    _buildSection('Sobre a Startup', _buildDescricao()),
                    const SizedBox(height: 20),
                    _buildSection('Captação & Tokens', _buildCaptacao()),
                    const SizedBox(height: 20),
                    _buildSection('Estrutura Societária', _buildSocios()),
                    const SizedBox(height: 20),
                    _buildSection('Informações Gerais', _buildInfoGeral()),
                    if (s.mentors.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSection('Mentores', _buildMentores()),
                    ],
                    const SizedBox(height: 28),
                    _buildInvestirButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: _purple900,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.bookmark_border_rounded,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_purple900, _purple600, _purple900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          s.name.length >= 2
                              ? s.name.substring(0, 2).toUpperCase()
                              : s.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _purple600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _Chip(
                                label: s.sector,
                                bg: Colors.white.withValues(alpha: 0.15),
                                textColor: Colors.white,
                              ),
                              _Chip(
                                label: s.stage,
                                bg: _stageColor(s.stage).withValues(alpha: 0.25),
                                textColor: _stageColor(s.stage),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.isActive ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          s.isActive ? 'Ativa' : 'Inativa',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: s.isActive ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 1, height: 14, color: _divider),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            s.status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildDescricao() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.description,
            maxLines: _descExpanded ? null : 4,
            overflow: _descExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _descExpanded = !_descExpanded;
              });
            },
            child: Text(
              _descExpanded ? 'Ver menos' : 'Ver mais',
              style: const TextStyle(
                fontSize: 13,
                color: _accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptacao() {
    final tokensVendidos = s.totalTokens - s.tokensAvailable;
    final pct = s.totalTokens > 0
        ? (tokensVendidos / s.totalTokens).clamp(0.0, 1.0)
        : 0.0;

    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCol(
                  label: 'Capital Investido',
                  value: _formatCurrency(s.capitalInvested),
                  color: _accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCol(
                  label: 'Total Investido',
                  value: _formatCurrency(s.totalInvested),
                  color: _textPrimary,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tokens vendidos',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: _purple100,
                  valueColor: const AlwaysStoppedAnimation(_accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: _divider, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TokenItem(
                  label: 'Preço Inicial',
                  value: 'R\$ ${s.initialPrice}',
                ),
              ),
              Expanded(
                child: _TokenItem(
                  label: 'Preço Atual',
                  value: 'R\$ ${s.currentPrice}',
                  color: s.currentPrice >= s.initialPrice
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TokenItem(
                  label: 'Total de Tokens',
                  value: '${s.totalTokens}',
                ),
              ),
              Expanded(
                child: _TokenItem(
                  label: 'Disponíveis',
                  value: '${s.tokensAvailable}',
                  color: s.tokensAvailable > 0 ? _accent : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _divider, height: 1),
          const SizedBox(height: 12),
          _buildMercadoSecundarioRow(),
        ],
      ),
    );
  }

  Widget _buildMercadoSecundarioRow() {
    return Row(
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 14,
          color: _textSecondary,
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Mercado secundário',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: _carregandoMercado
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _accent,
              ),
            )
                : Text(
              _menorPrecoMercado != null
                  ? 'A partir de R\$ ${_menorPrecoMercado!.toStringAsFixed(2)}'
                  : 'Nenhuma oferta ativa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _menorPrecoMercado != null
                    ? _accent
                    : _textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocios() {
    if (s.founders.isEmpty) {
      return _Card(
        child: const Text(
          'Nenhum fundador cadastrado.',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    final colors = [
      _purple600,
      const Color(0xFF00C896),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFF00BFFF),
    ];

    return Column(
      children: [
        if (_foundersHavePercentage()) ...[
          _Card(
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(180, 180),
                        painter: _PiePainter(
                          founders: s.founders,
                          colors: colors,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${s.founders.length}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: _textPrimary,
                            ),
                          ),
                          const Text(
                            'fundadores',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: List.generate(s.founders.length, (i) {
                    final founder = s.founders[i];
                    final nome = _extractName(founder);

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          nome.split(' ').first,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        ...List.generate(s.founders.length, (i) {
          final founder = s.founders[i];
          final nome = _extractName(founder);
          final cargo = _extractRole(founder);
          final pct = _extractPercentage(founder);

          final initials = nome.length >= 2
              ? nome.substring(0, 2).toUpperCase()
              : nome.toUpperCase();

          final color = colors[i % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Card(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        if (cargo.isNotEmpty)
                          Text(
                            cargo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (pct != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoGeral() {
    return _Card(
      child: Column(
        children: [
          _InfoRow(Icons.category_rounded, 'Setor', s.sector),
          const Divider(color: _divider, height: 24),
          _InfoRow(Icons.trending_up_rounded, 'Estágio', s.stage),
          const Divider(color: _divider, height: 24),
          _InfoRow(Icons.circle, 'Status', s.status),
          if (s.videoDemo.isNotEmpty) ...[
            const Divider(color: _divider, height: 24),
            _InfoRow(
              Icons.play_circle_outline_rounded,
              'Demo',
              s.videoDemo,
              isLink: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMentores() {
    return Column(
      children: s.mentors.map((mentor) {
        final nome = _extractName(mentor);
        final cargo = _extractRole(mentor);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Card(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _purple100,
                  child: Text(
                    nome.isNotEmpty ? nome[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _purple600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      if (cargo.isNotEmpty)
                        Text(
                          cargo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvestirButton() {
    final podeInvestir = s.isActive && s.tokensAvailable > 0 && !_comprandoTokens;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: podeInvestir ? _comprarTokens : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple600,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _comprandoTokens
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rocket_launch_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                s.tokensAvailable > 0
                    ? 'Investir agora'
                    : 'Tokens esgotados',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractName(dynamic founder) {
    if (founder is Map) {
      return founder['name']?.toString() ??
          founder['nome']?.toString() ??
          '';
    }

    return founder.toString();
  }

  String _extractRole(dynamic founder) {
    if (founder is Map) {
      return founder['role']?.toString() ??
          founder['cargo']?.toString() ??
          '';
    }

    return '';
  }

  double? _extractPercentage(dynamic founder) {
    if (founder is Map) {
      final value = founder['percentage'] ??
          founder['percentual'] ??
          founder['participation'] ??
          founder['participacao'];

      if (value != null) {
        return (value as num).toDouble();
      }
    }

    return null;
  }

  bool _foundersHavePercentage() {
    return s.founders.any((founder) => _extractPercentage(founder) != null);
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  const _StatCol({
    required this.label,
    required this.value,
    required this.color,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TokenItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _TokenItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color ?? _textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;

  const _InfoRow(
      this.icon,
      this.label,
      this.value, {
        this.isLink = false,
      });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accent),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: _textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isLink ? _accent : _textPrimary,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<dynamic> founders;
  final List<Color> colors;

  const _PiePainter({
    required this.founders,
    required this.colors,
  });

  double _pct(dynamic founder) {
    if (founder is Map) {
      final value = founder['percentage'] ??
          founder['percentual'] ??
          founder['participation'] ??
          founder['participacao'];

      if (value != null) {
        return (value as num).toDouble();
      }
    }

    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = founders.fold<double>(
      0,
          (sum, founder) => sum + _pct(founder),
    );

    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < founders.length; i++) {
      final sweep = 2 * math.pi * (_pct(founders[i]) / total);

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweep,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
      startAngle += sweep;
    }

    canvas.drawCircle(
      center,
      48,
      Paint()..color = _surface,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NumberParser {
  static double? toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}