// Felipe Ragonha
// RA: 24023900

// Juliano Perusso
// RA: 24023434

import 'package:flutter/material.dart';
import '../models/startup.dart';
import '../services/startup_service.dart';
import '../widgets/startup_card.dart';
import '../widgets/startup_video_player.dart';
import 'startup_detail_screen.dart';
import 'profile_screen.dart';

const _purple900 = Color(0xFF3A1C71);
const _purple600 = Color(0xFF6A4CFF);
const _bg = Color(0xFFF2F5F9);
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);

class CatalogoStartupsScreen extends StatefulWidget {
  const CatalogoStartupsScreen({super.key});

  @override
  State<CatalogoStartupsScreen> createState() => _CatalogoStartupsScreenState();
}

class _CatalogoStartupsScreenState extends State<CatalogoStartupsScreen> {
  final StartupService _service = StartupService();

  late Future<List<Startup>> _startupsFuture;

  String _filtroTexto = '';
  String _filtroEstagio = 'Todos';

  final List<String> _estagios = [
    'Todos',
    'Nova',
    'Em operação',
    'Em expansão',
  ];

  @override
  void initState() {
    super.initState();
    _startupsFuture = _service.listStartups();
  }

  Future<void> _recarregarStartups() async {
    setState(() {
      _startupsFuture = _service.listStartups();
    });
  }

  bool _matchEstagio(String stageBanco, String filtroSelecionado) {
    final stage = stageBanco.toLowerCase().trim();

    switch (filtroSelecionado) {
      case 'Nova':
        return stage == 'nova' ||
            stage == 'ideacao' ||
            stage == 'ideação' ||
            stage == 'ideia' ||
            stage == 'seed' ||
            stage == 'mvp';

      case 'Em operação':
        return stage == 'operacao' || stage == 'operação' || stage == 'ativa';

      case 'Em expansão':
        return stage == 'expansao' ||
            stage == 'expansão' ||
            stage == 'scaleup' ||
            stage == 'scale-up' ||
            stage == 'growth' ||
            stage == 'crescimento' ||
            stage == 'tracao' ||
            stage == 'tração' ||
            stage == 'serie a' ||
            stage == 'series a';

      default:
        return true;
    }
  }

  List<Startup> _filtrarStartups(List<Startup> startups) {
    return startups.where((startup) {
      final texto = _filtroTexto.toLowerCase().trim();

      final matchTexto =
          texto.isEmpty ||
          startup.name.toLowerCase().contains(texto) ||
          startup.sector.toLowerCase().contains(texto);

      final matchEstagio = _matchEstagio(startup.stage, _filtroEstagio);

      return matchTexto && matchEstagio;
    }).toList();
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openStartupVideo(Startup startup) {
    showDialog<void>(
      context: context,
      builder: (_) => StartupVideoDialog(
        startupName: startup.name,
        videoPath: startup.videoDemo,
      ),
    );
  }

  String _formatCompact(num value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
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
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Perfil',
            onPressed: _openProfile,
          ),
        ],
      ),
      body: FutureBuilder<List<Startup>>(
        future: _startupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple600),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: _purple600,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erro ao carregar startups: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _recarregarStartups,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final startups = snapshot.data ?? [];
          final startupsFiltradas = _filtrarStartups(startups);
          final activeCount = startups
              .where((startup) => startup.isActive)
              .length;
          final availableTokens = startups.fold<int>(
            0,
            (sum, startup) => sum + startup.tokensAvailable,
          );
          final availableValue = startups.fold<int>(
            0,
            (sum, startup) =>
                sum + (startup.tokensAvailable * startup.currentPrice),
          );

          return RefreshIndicator(
            color: _purple600,
            onRefresh: _recarregarStartups,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _CatalogHeader(
                  totalStartups: startups.length,
                  activeStartups: activeCount,
                  availableTokens: availableTokens,
                  availableValue: _formatCompact(availableValue),
                ),
                const SizedBox(height: 14),
                _SearchBox(
                  onChanged: (value) {
                    setState(() {
                      _filtroTexto = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _StageSelector(
                  stages: _estagios,
                  selectedStage: _filtroEstagio,
                  onSelected: (stage) {
                    setState(() {
                      _filtroEstagio = stage;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Oportunidades',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${startupsFiltradas.length} ativo${startupsFiltradas.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (startupsFiltradas.isEmpty)
                  const _EmptyCatalog()
                else
                  ...startupsFiltradas.map(
                    (startup) => StartupCard(
                      startup: startup,
                      onPlayVideo: () => _openStartupVideo(startup),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StartupDetailScreen(startup: startup),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  final int totalStartups;
  final int activeStartups;
  final int availableTokens;
  final String availableValue;

  const _CatalogHeader({
    required this.totalStartups,
    required this.activeStartups,
    required this.availableTokens,
    required this.availableValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple900, _purple600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _purple600.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Startups Mescla',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Oportunidades para investir',
                      maxLines: 2,
                      style: TextStyle(color: Color(0xFFEDE7FF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Listadas',
                  value: '$totalStartups',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HeaderMetric(label: 'Ativas', value: '$activeStartups'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Tokens',
                  value: '$availableTokens',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HeaderMetric(
                  label: 'Disponível',
                  value: availableValue,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _HeaderMetric({
    required this.label,
    required this.value,
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
          style: const TextStyle(color: Color(0xFFEDE7FF), fontSize: 11),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Buscar por nome ou setor',
        hintStyle: const TextStyle(color: _textSecondary),
        prefixIcon: const Icon(Icons.search_rounded, color: _purple600),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _purple600, width: 1.4),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _StageSelector extends StatelessWidget {
  final List<String> stages;
  final String selectedStage;
  final ValueChanged<String> onSelected;

  const _StageSelector({
    required this.stages,
    required this.selectedStage,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final stage = stages[index];
          final selected = selectedStage == stage;

          return ChoiceChip(
            label: Text(stage),
            selected: selected,
            selectedColor: _purple600,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? _purple600 : const Color(0xFFE6E8F0),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            onSelected: (_) => onSelected(stage),
          );
        },
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.manage_search_rounded, color: _purple600, size: 42),
          SizedBox(height: 12),
          Text(
            'Nenhuma startup encontrada',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tente outro termo ou ajuste o filtro de estágio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
