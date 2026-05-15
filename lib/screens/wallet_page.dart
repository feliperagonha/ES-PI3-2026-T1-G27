// Guilherme Marras
// RA: 24027681

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';

const colorEletricViolet = Color(0xFF7E4EFC);
const colorVioletBlue = Color(0xFF6839EC);
const colorCyanBlue = Color(0xFFF2F5F9);
const colorZircon = Color(0xFFEBEEF7);

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  final TextEditingController _balanceController = TextEditingController(
    text: '1000',
  );

  late Future<_WalletData> _walletFuture;
  bool _addingBalance = false;
  bool _showAddBalanceForm = false;

  @override
  void initState() {
    super.initState();
    _walletFuture = _loadWallet();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<_WalletData> _loadWallet() async {
    final results =
        await Future.wait([
          _functions.httpsCallable('fetchWallet').call(),
          _functions.httpsCallable('listInvestorPositions').call(),
        ]).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception(
              'Tempo esgotado ao carregar carteira. Verifique a conexao ou as permissoes das functions.',
            );
          },
        );

    final walletResult = results[0];
    final positionsResult = results[1];

    final walletRaw = walletResult.data;
    final positionsRaw = positionsResult.data;

    final walletData = walletRaw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(walletRaw);

    final positionsResponse = positionsRaw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(positionsRaw);

    final positionsList = List<Map<String, dynamic>>.from(
      ((positionsResponse['data'] ?? []) as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    final balance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
    final positions = positionsList.map(WalletTokenPosition.fromJson).toList();

    return _WalletData(balance: balance, positions: positions);
  }

  void _refreshData() {
    setState(() {
      _walletFuture = _loadWallet();
    });
  }

  void _toggleAddBalanceForm() {
    setState(() {
      _showAddBalanceForm = !_showAddBalanceForm;
    });
  }

  Future<void> _submitAddBalance() async {
    final normalized = _balanceController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final amount = double.tryParse(normalized);

    if (amount == null || amount <= 0) {
      _snack('Digite um valor valido para adicionar saldo.');
      return;
    }

    setState(() => _addingBalance = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _snack('Sessao expirada. Faca login novamente.');
        return;
      }

      await currentUser.getIdToken(true);
      await _functions.httpsCallable('addBalance').call({'amount': amount});
      if (!mounted) {
        return;
      }

      _snack('Saldo adicionado com sucesso.', success: true);
      setState(() {
        _showAddBalanceForm = false;
        _balanceController.text = '1000';
      });
      _refreshData();
    } on FirebaseFunctionsException catch (e) {
      final message = e.code == 'unauthenticated'
          ? 'Sessao expirada. Faca login novamente.'
          : e.message ?? 'Erro ao adicionar saldo: ${e.code}';
      _snack(message);
    } catch (e) {
      _snack('Erro inesperado ao adicionar saldo: $e');
    } finally {
      if (mounted) {
        setState(() => _addingBalance = false);
      }
    }
  }

  void _snack(String message, {bool success = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? colorVioletBlue : null,
      ),
    );
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Usuario nao logado')));
    }

    return Scaffold(
      backgroundColor: colorCyanBlue,
      appBar: AppBar(
        backgroundColor: colorCyanBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Minha Carteira',
          style: TextStyle(color: colorVioletBlue, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded, color: colorVioletBlue),
          ),
          IconButton(
            onPressed: _openProfile,
            tooltip: 'Perfil',
            icon: const Icon(
              Icons.person_outline_rounded,
              color: colorVioletBlue,
            ),
          ),
        ],
      ),
      body: FutureBuilder<_WalletData>(
        future: _walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: colorVioletBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar carteira:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final wallet = snapshot.data;

          if (wallet == null) {
            return const Center(child: Text('Nenhum dado encontrado'));
          }

          return RefreshIndicator(
            color: colorVioletBlue,
            onRefresh: () async {
              _refreshData();
              await _walletFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _BalanceCard(
                  balanceText: _formatMoney(wallet.balance),
                  addingBalance: _addingBalance,
                  showAddBalanceForm: _showAddBalanceForm,
                  amountController: _balanceController,
                  onToggleAddBalance: _addingBalance
                      ? null
                      : _toggleAddBalanceForm,
                  onSubmitBalance: _addingBalance ? null : _submitAddBalance,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Meus tokens',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                if (wallet.positions.isEmpty)
                  const _EmptyTokensCard()
                else
                  ...wallet.positions.map(
                    (position) => _TokenPositionCard(position: position),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WalletData {
  final double balance;
  final List<WalletTokenPosition> positions;

  const _WalletData({required this.balance, required this.positions});
}

class WalletTokenPosition {
  final String startupId;
  final String startupName;
  final int totalQuantity;
  final int availableQuantity;
  final int reservedQuantity;

  const WalletTokenPosition({
    required this.startupId,
    required this.startupName,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.reservedQuantity,
  });

  factory WalletTokenPosition.fromJson(Map<String, dynamic> json) {
    final availableQuantity = (json['availableQuantity'] as num?)?.toInt() ?? 0;
    final reservedQuantity = (json['reservedQuantity'] as num?)?.toInt() ?? 0;
    final totalQuantity =
        (json['totalQuantity'] as num?)?.toInt() ??
        (json['quantity'] as num?)?.toInt() ??
        availableQuantity + reservedQuantity;

    return WalletTokenPosition(
      startupId: json['startupId']?.toString() ?? '',
      startupName: json['startupName']?.toString() ?? 'Startup',
      totalQuantity: totalQuantity,
      availableQuantity: availableQuantity,
      reservedQuantity: reservedQuantity,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String balanceText;
  final bool addingBalance;
  final bool showAddBalanceForm;
  final TextEditingController amountController;
  final VoidCallback? onToggleAddBalance;
  final VoidCallback? onSubmitBalance;

  const _BalanceCard({
    required this.balanceText,
    required this.addingBalance,
    required this.showAddBalanceForm,
    required this.amountController,
    required this.onToggleAddBalance,
    required this.onSubmitBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [colorVioletBlue, colorEletricViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo disponivel',
            style: TextStyle(color: colorZircon, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            balanceText,
            style: const TextStyle(
              color: colorCyanBlue,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onToggleAddBalance,
              icon: addingBalance
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorVioletBlue,
                      ),
                    )
                  : const Icon(Icons.add_card_rounded),
              label: Text(showAddBalanceForm ? 'Fechar' : 'Adicionar saldo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorVioletBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (showAddBalanceForm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              enabled: !addingBalance,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.14),
                labelText: 'Valor em reais',
                labelStyle: const TextStyle(color: colorZircon),
                prefixText: 'R\$ ',
                prefixStyle: const TextStyle(color: colorZircon),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmitBalance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorCyanBlue,
                  foregroundColor: colorVioletBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: addingBalance
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorVioletBlue,
                        ),
                      )
                    : const Text('Confirmar saldo'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TokenPositionCard extends StatelessWidget {
  final WalletTokenPosition position;

  const _TokenPositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                position.startupName.length >= 2
                    ? position.startupName.substring(0, 2).toUpperCase()
                    : position.startupName.toUpperCase(),
                style: const TextStyle(
                  color: colorVioletBlue,
                  fontWeight: FontWeight.w900,
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
                  position.startupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: ${position.totalQuantity} token${position.totalQuantity == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'Disponivel: ${position.availableQuantity} | Em oferta: ${position.reservedQuantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTokensCard extends StatelessWidget {
  const _EmptyTokensCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.token_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Voce ainda nao possui tokens.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Compre tokens de startups para eles aparecerem aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
