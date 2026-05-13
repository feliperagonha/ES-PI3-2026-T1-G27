// Felipe Ragonha
// RA: 24023900

// Juliano Perusso
// RA: 24023434

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/oferta.dart';
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

  Future<List<Oferta>>? _ofertasFuture;

  bool _comprando = false;
  bool _alterouOfertas = false;

  @override
  void initState() {
    super.initState();
    _ofertasFuture = _service.getOfertasPorStartup(widget.startupId);
  }

  void _recarregarOfertas() {
    setState(() {
      _ofertasFuture = _service.getOfertasPorStartup(widget.startupId);
    });
  }

  void _voltar() {
    Navigator.pop(context, _alterouOfertas);
  }

  Future<void> _comprar(Oferta oferta) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    if (oferta.vendedorId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não pode comprar sua própria oferta.'),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Comprar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _comprando = true;
    });

    try {
      await _service.comprarToken(ofertaId: oferta.id);

      if (!mounted) return;

      _alterouOfertas = true;
      _recarregarOfertas();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra realizada com sucesso!'),
          backgroundColor: Color(0xFF6A4CFF),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao comprar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _comprando = false;
        });
      }
    }
  }

  Future<void> _cancelarOferta(Oferta oferta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cancelar oferta'),
        content: const Text('Tem certeza que deseja cancelar esta oferta?'),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancelar oferta',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _service.cancelarOferta(oferta.id);

      if (!mounted) return;

      _alterouOfertas = true;
      _recarregarOfertas();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oferta cancelada.'),
          backgroundColor: Color(0xFF6A4CFF),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar oferta: $e')),
      );
    }
  }

  Future<void> _irParaStartup() async {
    try {
      final startups = await _startupRepo.listStartups();

      final startupEncontrada = startups.where(
            (startup) => startup.id == widget.startupId,
      );

      if (!mounted) return;

      if (startupEncontrada.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StartupDetailScreen(
              startup: startupEncontrada.first,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Startup não encontrada.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _atualizarPorArrastar() async {
    _recarregarOfertas();
    await _ofertasFuture;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _voltar();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3A1C71),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _voltar,
          ),
          title: Text(
            widget.startupName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.open_in_new_rounded,
                color: Colors.white,
              ),
              tooltip: 'Ver startup',
              onPressed: _irParaStartup,
            ),
          ],
        ),
        body: FutureBuilder<List<Oferta>>(
          future: _ofertasFuture ??=
              _service.getOfertasPorStartup(widget.startupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6A4CFF),
                ),
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
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            final ofertas = snapshot.data ?? [];

            if (ofertas.isEmpty) {
              return RefreshIndicator(
                color: const Color(0xFF6A4CFF),
                onRefresh: _atualizarPorArrastar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
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
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: const Color(0xFF6A4CFF),
              onRefresh: _atualizarPorArrastar,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: ofertas.length,
                itemBuilder: (context, index) {
                  final oferta = ofertas[index];
                  final isMinhaOferta = oferta.vendedorId == userId;

                  return _OfertaCard(
                    oferta: oferta,
                    isMinhaOferta: isMinhaOferta,
                    comprando: _comprando,
                    onComprar: () => _comprar(oferta),
                    onCancelar: () => _cancelarOferta(oferta),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OfertaCard extends StatelessWidget {
  final Oferta oferta;
  final bool isMinhaOferta;
  final bool comprando;
  final VoidCallback onComprar;
  final VoidCallback onCancelar;

  const _OfertaCard({
    required this.oferta,
    required this.isMinhaOferta,
    required this.comprando,
    required this.onComprar,
    required this.onCancelar,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isMinhaOferta)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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

            if (isMinhaOferta)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: onCancelar,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Cancelar oferta',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: comprando ? null : onComprar,
                  icon: const Icon(
                    Icons.shopping_cart_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: comprando
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Comprar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A4CFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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