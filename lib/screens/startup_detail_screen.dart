import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/startup.dart';

// Cores
const _purple900 = Color(0xFF3A1C71);
const _purple600 = Color(0xFF6A4CFF);
const _purple400 = Color(0xFF7C4DFF);
const _purple100 = Color(0xFFEDE7FF);
const _accent    = Color(0xFF6A4CFF);
const _bg        = Color(0xFFF1F1F1);
const _surface   = Colors.white;
const _textPrimary   = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);
const _divider   = Color(0xFFE5E7EB);

class StartupDetailScreen extends StatefulWidget {
  final Startup startup;
  const StartupDetailScreen({super.key, required this.startup});

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  bool _descExpanded = false;

  Startup get s => widget.startup;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Stages

  Color _stageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'ideacao':   return Colors.orange;
      case 'mvp':       return Colors.blue;
      case 'seed':      return Colors.purple;
      case 'operacao':  return Colors.green;
      default:          return Colors.grey;
    }
  }

  String _formatCurrency(int value) {
    if (value >= 1000000) return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000)    return 'R\$ ${(value / 1000).toStringAsFixed(0)}K';
    return 'R\$ $value';
  }

  // build

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
                    _StatusRow(),
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

  // SLIVER APP BAR

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: _purple900,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
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
              // Círculo decorativo (igual ao padrão visual do projeto)
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
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
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // Conteúdo
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Logo box
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
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
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _Chip(
                                label: s.sector,
                                bg: Colors.white.withOpacity(0.15),
                                textColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              _Chip(
                                label: s.stage,
                                bg: _stageColor(s.stage).withOpacity(0.25),
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

  // STATUS ROW (isActive + status)

  Widget _StatusRow() {
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
        Text(
          s.status,
          style: const TextStyle(fontSize: 13, color: _textSecondary),
        ),
      ],
    );
  }

  // SEÇÃO GENÉRICA

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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  // DESCRIÇÃO

  Widget _buildDescricao() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.description,
            maxLines: _descExpanded ? null : 4,
            overflow:
            _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
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

  // CAPTAÇÃO & TOKENS

  Widget _buildCaptacao() {
    final tokensVendidos = s.totalTokens - s.tokensAvailable;
    final pct = s.totalTokens > 0
        ? (tokensVendidos / s.totalTokens).clamp(0.0, 1.0)
        : 0.0;

    return _Card(
      child: Column(
        children: [
          // Linha de valores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCol(
                label: 'Capital Investido',
                value: _formatCurrency(s.capitalInvested),
                color: _accent,
              ),
              _StatCol(
                label: 'Total Investido',
                value: _formatCurrency(s.totalInvested),
                color: _textPrimary,
                align: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Barra de tokens vendidos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tokens vendidos',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
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
          // Grid de tokens
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
        ],
      ),
    );
  }

  // ESTRUTURA SOCIETÁRIA (founders)

  Widget _buildSocios() {
    if (s.founders.isEmpty) {
      return _Card(
        child: const Text(
          'Nenhum fundador cadastrado.',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    // Cores para o gráfico e avatares
    final colors = [
      _purple600,
      const Color(0xFF00C896),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFF00BFFF),
    ];

    return Column(
      children: [
        // Gráfico de pizza (se founders tiverem percentual)
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
                            style:
                            TextStyle(fontSize: 11, color: _textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Legenda
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: List.generate(s.founders.length, (i) {
                    final f = s.founders[i];
                    final nome = _extractName(f);
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
        // Cards individuais dos fundadores
        ...List.generate(s.founders.length, (i) {
          final f = s.founders[i];
          final nome = _extractName(f);
          final cargo = _extractRole(f);
          final pct = _extractPercentage(f);
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
                    backgroundColor: color.withOpacity(0.15),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        if (cargo.isNotEmpty)
                          Text(
                            cargo,
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
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
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

  // INFORMAÇÕES GERAIS

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
            _InfoRow(Icons.play_circle_outline_rounded, 'Demo', s.videoDemo,
                isLink: true),
          ],
        ],
      ),
    );
  }

  // MENTORES

  Widget _buildMentores() {
    return Column(
      children: s.mentors.map((m) {
        final nome = _extractName(m);
        final cargo = _extractRole(m);
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        )),
                    if (cargo.isNotEmpty)
                      Text(cargo,
                          style: const TextStyle(
                              fontSize: 12, color: _textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // BOTÃO INVESTIR

  Widget _buildInvestirButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: s.isActive && s.tokensAvailable > 0
            ? () {
          // TODO: navegar para tela de investimento
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text('Investir em ${s.name} — em breve!'),
              backgroundColor: _accent,
            ),
          );
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple600,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch_rounded,
                size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              s.tokensAvailable > 0 ? 'Investir agora' : 'Tokens esgotados',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers de founders (List<dynamic>)
  // O Firestore pode retornar Map ou String

  String _extractName(dynamic f) {
    if (f is Map) return f['name']?.toString() ?? f['nome']?.toString() ?? '';
    return f.toString();
  }

  String _extractRole(dynamic f) {
    if (f is Map) return f['role']?.toString() ?? f['cargo']?.toString() ?? '';
    return '';
  }

  double? _extractPercentage(dynamic f) {
    if (f is Map) {
      final v = f['percentage'] ?? f['percentual'];
      if (v != null) return (v as num).toDouble();
    }
    return null;
  }

  bool _foundersHavePercentage() {
    return s.founders.any((f) => _extractPercentage(f) != null);
  }
}

//  WIDGETS INTERNOS

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
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

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _Chip(
      {required this.label, required this.bg, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;
  const _StatCol(
      {required this.label,
        required this.value,
        required this.color,
        this.align = CrossAxisAlignment.start});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: _textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _TokenItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _TokenItem({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: _textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color ?? _textPrimary)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  const _InfoRow(this.icon, this.label, this.value, {this.isLink = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accent),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 14, color: _textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
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

//  PIE CHART PAINTER

class _PiePainter extends CustomPainter {
  final List<dynamic> founders;
  final List<Color> colors;
  const _PiePainter({required this.founders, required this.colors});

  double _pct(dynamic f) {
    if (f is Map) {
      final v = f['percentage'] ?? f['percentual'];
      if (v != null) return (v as num).toDouble();
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = founders.fold<double>(0, (sum, f) => sum + _pct(f));
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
        ..arcTo(Rect.fromCircle(center: center, radius: radius), startAngle,
            sweep, false)
        ..close();

      canvas.drawPath(path, paint);
      startAngle += sweep;
    }

    canvas.drawCircle(center, 48, Paint()..color = _surface);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}