// Felipe Ragonha
// RA: 24023900

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/oferta.dart';
import '../models/startup.dart';
import '../services/mercado_service.dart';
import '../repositories/startup_repository.dart';
import 'startup_detail_screen.dart';

class MercadoStartupDetailScreen extends StatefulWidget {
  final String startupId;
  final String startupName;

  const MercadoStartupDetailScreen({
    super.key,
    required this.startupId,
    required this.startupName,
  });

  @override
  State<MercadoStartupDetailScreen> createState() =>
      _MercadoStartupDetailScreenState();
}

class _MercadoStartupDetailScreenState
    extends State<MercadoStartupDetailScreen> {
  final MercadoService _service = MercadoService();
  final StartupRepository _startupRepo = StartupRepository();
  bool _comprando = false;

  Future<void> _comprar(Oferta oferta) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (oferta.vendedorId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Você não pode comprar sua própria oferta.')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar compra'),
        content: Text(
          'Comprar ${oferta.quantidade} token${oferta.quantidade > 1 ? 's' : ''} '
          'de ${oferta.startupName} por R\$ ${oferta.preco.toStringAsFixed(2)} cada?\n\n'
          'Total: R\$ ${(oferta.preco * oferta.quantidade).toStringAsFixed(2)}',
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
            child: const Text('Comprar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _comprando = true);
    try {
      await _service.comprarToken(ofertaId: oferta.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra realizada com sucesso!'),
          backgroundColor: Color(0xFF6A4CFF),
        ),
      );
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao comprar: $e')),
      );
    } finally {
      if (mounted) setState(() => _comprando = false);
    }
  }

  Future<void> _cancelarOferta(Oferta oferta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar oferta'),
        content:
            const Text('Tem certeza que deseja cancelar esta oferta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar oferta',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _service.cancelarOferta(oferta.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Oferta cancelada.')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _irParaStartup() async {
    try {
      final startups = await _startupRepo.getStartups().first;
      final startup = startups.where((s) => s.id == widget.startupId).firstOrNull;
      if (!mounted) return;
      if (startup != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StartupDetailScreen(startup: startup)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Startup não encontrada.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A1C71),
        foregroundColor: Colors.white,
        title: Text(
          widget.startupName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
            tooltip: 'Ver startup',
            onPressed: _irParaStartup,
          ),
        ],
      ),
      body: StreamBuilder<List<Oferta>>(
        stream: _service.getOfertasPorStartup(widget.startupId),
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

          if (ofertas.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum token à venda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ofertas.length,
            itemBuilder: (context, index) {
              final oferta = ofertas[index];
              final isMinhaOferta = oferta.vendedorId == userId;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho: vendedor
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFEDE7FF),
                            child: Text(
                              oferta.vendedorNome.isNotEmpty
                                  ? oferta.vendedorNome[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6A4CFF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMinhaOferta ? 'Você' : oferta.vendedorNome,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                if (oferta.criadoEm != null)
                                  Text(
                                    _formatDate(oferta.criadoEm!),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280)),
                                  ),
                              ],
                            ),
                          ),
                          if (isMinhaOferta)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE7FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Sua oferta',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6A4CFF),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 14),

                      // Detalhes
                      Row(
                        children: [
                          Expanded(
                            child: _DetalheItem(
                              label: 'Quantidade',
                              value:
                                  '${oferta.quantidade} token${oferta.quantidade > 1 ? 's' : ''}',
                            ),
                          ),
                          Expanded(
                            child: _DetalheItem(
                              label: 'Preço por token',
                              value: 'R\$ ${oferta.preco.toStringAsFixed(2)}',
                              color: const Color(0xFF6A4CFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _DetalheItem(
                        label: 'Total da oferta',
                        value:
                            'R\$ ${(oferta.preco * oferta.quantidade).toStringAsFixed(2)}',
                        color: const Color(0xFF3A1C71),
                        large: true,
                      ),

                      const SizedBox(height: 16),

                      // Botão comprar ou cancelar
                      if (isMinhaOferta)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelarOferta(oferta),
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: Colors.red),
                            label: const Text('Cancelar oferta',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed:
                                _comprando ? null : () => _comprar(oferta),
                            icon: const Icon(Icons.shopping_cart_rounded,
                                size: 16, color: Colors.white),
                            label: _comprando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Comprar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A4CFF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _DetalheItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool large;

  const _DetalheItem({
    required this.label,
    required this.value,
    this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: color ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
