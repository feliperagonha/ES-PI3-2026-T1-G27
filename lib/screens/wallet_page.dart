// Guilherme Marras
// RA: 24027681

//Juliano Perusso
//RA: 24023434

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final user = FirebaseAuth.instance.currentUser;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  late Future<_WalletData> _walletFuture;

  @override
  void initState() {
    super.initState();
    _walletFuture = _carregarCarteira();
  }

  Future<_WalletData> _carregarCarteira() async {
    final walletResult = await _functions.httpsCallable('fetchWallet').call();
    final positionsResult =
    await _functions.httpsCallable('listInvestorPositions').call();

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

    final positions = positionsList.map((item) {
      return WalletTokenPosition.fromJson(item);
    }).toList();

    return _WalletData(
      balance: balance,
      positions: positions,
    );
  }

  void _refreshData() {
    setState(() {
      _walletFuture = _carregarCarteira();
    });
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuário não logado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorCyanBlue,
      appBar: AppBar(
        backgroundColor: colorCyanBlue,
        elevation: 0,
        leading: const BackButton(color: colorVioletBlue),
        title: const Text(
          'Minha Carteira',
          style: TextStyle(
            color: colorVioletBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(
              Icons.refresh_rounded,
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
            return const Center(
              child: Text('Nenhum dado encontrado'),
            );
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

  const _WalletData({
    required this.balance,
    required this.positions,
  });
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
    final availableQuantity =
        (json['availableQuantity'] as num?)?.toInt() ?? 0;

    final reservedQuantity =
        (json['reservedQuantity'] as num?)?.toInt() ?? 0;

    final totalQuantity =
        (json['totalQuantity'] as num?)?.toInt() ??
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

  const _BalanceCard({
    required this.balanceText,
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
            'Saldo disponível',
            style: TextStyle(
              color: colorZircon,
              fontSize: 14,
            ),
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
        ],
      ),
    );
  }
}

class _TokenPositionCard extends StatelessWidget {
  final WalletTokenPosition position;

  const _TokenPositionCard({
    required this.position,
  });

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
                  'Disponível: ${position.availableQuantity} · Em oferta: ${position.reservedQuantity}',
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
          Icon(
            Icons.token_rounded,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'Você ainda não possui tokens.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Compre tokens de startups para eles aparecerem aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}