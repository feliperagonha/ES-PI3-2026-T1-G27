// Guilherme Marras - 24027681
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Paleta de cores definida no Figma
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
  late Future<HttpsCallableResult> _fetchWalletFuture;

  @override
  void initState() {
    super.initState();
    _fetchWalletFuture = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .httpsCallable('fetchWallet')();
  }

  void _refreshData() {
    setState(() {
      _fetchWalletFuture = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
          .httpsCallable('fetchWallet')();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não logado")),
      );
    }

    return Scaffold(
      backgroundColor: colorCyanBlue,
      appBar: AppBar(
        backgroundColor: colorCyanBlue,
        elevation: 0,
        leading: const BackButton(color: colorVioletBlue),
        title: const Text(
          "Minha Carteira",
          style: TextStyle(color: colorVioletBlue),
        ),
      ),
      body: FutureBuilder<HttpsCallableResult>(
        future: _fetchWalletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: colorVioletBlue));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar dados: ${snapshot.error}"));
          }

          final rawData = snapshot.data?.data;
          if (rawData == null) {
            return const Center(child: Text("Nenhum dado encontrado"));
          }

          final data = Map<String, dynamic>.from(rawData);
          final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [colorVioletBlue, colorEletricViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Saldo disponível",
                            style: TextStyle(color: colorZircon),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "R\$ ${balance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: colorCyanBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator(color: colorVioletBlue)),
                      );

                      final res = await FirebaseFunctions.instanceFor(region: 'southamerica-east1')
                          .httpsCallable('addBalance')({
                            'amount': 10.0, 
                          });

                      if (context.mounted) Navigator.of(context).pop();

                      final resData = Map<String, dynamic>.from(res.data);
                      if (resData['success'] == true) {
                        _refreshData(); 
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resData['message'] ?? 'Sucesso!')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erro ao adicionar: $e")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorVioletBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "ADICIONAR SALDO",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
