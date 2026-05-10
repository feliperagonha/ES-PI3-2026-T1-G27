// Felipe Ragonha
// RA: 24023900

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/oferta.dart';
import '../services/mercado_service.dart';
import 'mercado_startup_detail_screen.dart';
import 'vender_token_screen.dart';

class MercadoScreen extends StatefulWidget {
  const MercadoScreen({super.key});

  @override
  State<MercadoScreen> createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  final MercadoService _service = MercadoService();
  String _busca = '';

  // Agrupa as ofertas por startup
  Map<String, List<Oferta>> _agrupar(List<Oferta> ofertas) {
    final Map<String, List<Oferta>> mapa = {};
    for (final o in ofertas) {
      mapa.putIfAbsent(o.startupId, () => []).add(o);
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
      ),
      body: Column(
        children: [
          // ── Busca ────────────────────────────────────
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
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),

          //Lista
          Expanded(
            child: StreamBuilder<List<Oferta>>(
              stream: _service.getOfertas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6A4CFF)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final ofertas = snapshot.data ?? [];

                final filtradas = _busca.isEmpty
                    ? ofertas
                    : ofertas
                        .where((o) => o.startupName
                            .toLowerCase()
                            .contains(_busca.toLowerCase()))
                        .toList();

                if (filtradas.isEmpty) {
                  return _EmptyState();
                }

                final agrupadas = _agrupar(filtradas);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: agrupadas.length,
                  itemBuilder: (context, index) {
                    final startupId = agrupadas.keys.elementAt(index);
                    final ofertasDaStartup = agrupadas[startupId]!;
                    final primeira = ofertasDaStartup.first;
                    final menorPreco = ofertasDaStartup
                        .map((o) => o.preco)
                        .reduce((a, b) => a < b ? a : b);

                    return _StartupMercadoCard(
                      oferta: primeira,
                      totalOfertas: ofertasDaStartup.length,
                      menorPreco: menorPreco,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MercadoStartupDetailScreen(
                            startupId: startupId,
                            startupName: primeira.startupName,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Vender token
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VenderTokenScreen(userId: user?.uid ?? ''),
          ),
        ),
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

//  Card de Startup no Mercado

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
      case 'ideacao':  return Colors.orange;
      case 'mvp':      return Colors.blue;
      case 'seed':     return Colors.purple;
      case 'operacao': return Colors.green;
      default:         return Colors.grey;
    }
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MiniChip(
                          label: oferta.startupSector,
                          color: const Color(0xFF6A4CFF),
                        ),
                        const SizedBox(width: 6),
                        _MiniChip(
                          label: oferta.startupStage,
                          color: _stageColor(oferta.startupStage),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalOfertas oferta${totalOfertas > 1 ? 's' : ''} disponível${totalOfertas > 1 ? 'is' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),

              // Menor preço + seta
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'a partir de',
                    style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    'R\$ ${menorPreco.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6A4CFF),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF6B7280)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  Empty State

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 72, color: Colors.grey.shade400),
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

//  mini chip

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
