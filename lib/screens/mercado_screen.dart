// Felipe Ragonha
// RA: 24023900

// Juliano Perusso
// RA: 24023434

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/oferta.dart';
import '../services/mercado_service.dart';
import 'mercado_startup_detail_screen.dart';
import 'profile_screen.dart';
import 'vender_token_screen.dart';

class MercadoScreen extends StatefulWidget {
  final int refreshTick;

  const MercadoScreen({super.key, this.refreshTick = 0});

  @override
  State<MercadoScreen> createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  final MercadoService _service = MercadoService();

  String _busca = '';
  late Future<List<Oferta>> _ofertasFuture;

  @override
  void initState() {
    super.initState();
    _ofertasFuture = _service.getOfertas();
  }

  @override
  void didUpdateWidget(covariant MercadoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshTick != widget.refreshTick) {
      _ofertasFuture = _service.getOfertas();
    }
  }

  void _recarregarOfertas() {
    setState(() {
      _ofertasFuture = _service.getOfertas();
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  // Agrupa as ofertas por startup
  Map<String, List<Oferta>> _agrupar(List<Oferta> ofertas) {
    final Map<String, List<Oferta>> mapa = {};

    for (final oferta in ofertas) {
      mapa.putIfAbsent(oferta.startupId, () => []).add(oferta);
    }

    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A1C71),
        foregroundColor: Colors.white,
        title: const Text(
          'Balcão de Tokens',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _recarregarOfertas,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: Column(
        children: [
          // Busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar startup...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6A4CFF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (valor) {
                setState(() {
                  _busca = valor;
                });
              },
            ),
          ),

          // Lista
          Expanded(
            child: FutureBuilder<List<Oferta>>(
              future: _ofertasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6A4CFF)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erro: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                final ofertas = snapshot.data ?? [];

                final filtradas = _busca.trim().isEmpty
                    ? ofertas
                    : ofertas.where((oferta) {
                        return oferta.startupName.toLowerCase().contains(
                          _busca.toLowerCase(),
                        );
                      }).toList();

                if (filtradas.isEmpty) {
                  return RefreshIndicator(
                    color: const Color(0xFF6A4CFF),
                    onRefresh: () async {
                      _recarregarOfertas();
                      await _ofertasFuture;
                    },
                    child: ListView(
                      children: const [SizedBox(height: 160), _EmptyState()],
                    ),
                  );
                }

                final agrupadas = _agrupar(filtradas);
                final startupsIds = agrupadas.keys.toList();

                return RefreshIndicator(
                  color: const Color(0xFF6A4CFF),
                  onRefresh: () async {
                    _recarregarOfertas();
                    await _ofertasFuture;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: startupsIds.length,
                    itemBuilder: (context, index) {
                      final startupId = startupsIds[index];
                      final ofertasDaStartup = agrupadas[startupId]!;
                      final primeiraOferta = ofertasDaStartup.first;

                      final menorPreco = ofertasDaStartup
                          .map((oferta) => oferta.preco)
                          .reduce((a, b) => a < b ? a : b);

                      return _StartupMercadoCard(
                        oferta: primeiraOferta,
                        totalOfertas: ofertasDaStartup.length,
                        menorPreco: menorPreco,
                        onTap: () async {
                          final alterou = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MercadoStartupDetailScreen(
                                startupId: startupId,
                                startupName: primeiraOferta.startupName,
                              ),
                            ),
                          );

                          if (alterou == true && mounted) {
                            _recarregarOfertas();
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Vender token
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final alterou = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => VenderTokenScreen(userId: user?.uid ?? ''),
            ),
          );

          if (alterou == true && mounted) {
            _recarregarOfertas();
          }
        },
        backgroundColor: const Color(0xFF6A4CFF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Vender token',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// Card de Startup no Mercado
class _StartupMercadoCard extends StatelessWidget {
  final Oferta oferta;
  final int totalOfertas;
  final double menorPreco;
  final VoidCallback onTap;

  const _StartupMercadoCard({
    required this.oferta,
    required this.totalOfertas,
    required this.menorPreco,
    required this.onTap,
  });

  Color _stageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'ideacao':
        return Colors.orange;
      case 'mvp':
        return Colors.blue;
      case 'seed':
        return Colors.purple;
      case 'operacao':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _textoQuantidadeOfertas() {
    if (totalOfertas == 1) {
      return '1 oferta disponível';
    }

    return '$totalOfertas ofertas disponíveis';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    oferta.startupName.length >= 2
                        ? oferta.startupName.substring(0, 2).toUpperCase()
                        : oferta.startupName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6A4CFF),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oferta.startupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniChip(
                          label: oferta.sector,
                          color: const Color(0xFF6A4CFF),
                        ),
                        _MiniChip(
                          label: oferta.stage,
                          color: _stageColor(oferta.stage),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _textoQuantidadeOfertas(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Menor preço + seta
              SizedBox(
                width: 105,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'a partir de',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),

                    const SizedBox(height: 2),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        'R\$ ${menorPreco.toStringAsFixed(2)}',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6A4CFF),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF6B7280),
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
}

// Empty State
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum token disponível',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seja o primeiro a vender tokens!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// Mini chip
class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
