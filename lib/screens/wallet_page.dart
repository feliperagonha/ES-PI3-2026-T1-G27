// Guilherme Marras - 24027681
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// FIREBASE PRECISA SER INTEGRADO (Lógica definida, mas collections e campos precisam ser adicionados conforme definidas no Firebase.
// trechos do código que precisam ser verificados estão marcados com comentários)

// Paleta de cores definida no Figma (convertidas para hexadecimal de 8 dígitos)
const colorEletricViolet = Color(0xFF7E4EFC);
const colorVioletBlue = Color(0xFF6839EC);
const colorCyanBlue = Color(0xFFF2F5F9);
const colorZircon = Color(0xFFEBEEF7);
const colorCitron = Color(0xFFE7D735);

class WalletPage extends StatefulWidget {
    const WalletPage({super.key});

    @override
    State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não logado")),
      );
    }

    final walletStream = FirebaseFirestore.instance
        .collection('wallets') //Verificar no Firebase nome correto da colletion
        .doc(user!.uid)
        .snapshots();

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
      body: StreamBuilder<DocumentSnapshot>(
        stream: walletStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Wallet não encontrada"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final totalBalance = data['totalBalance'] ?? 0;
          final availableBalance = data['availableBalance'] ?? 0;
          final portfolioValue = data['portfolioValue'] ?? 0;
          final profit = data['profit'] ?? 0;
          final profitPercentage = data['profitPercentage'] ?? 0;

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
                            "Patrimônio total",
                            style: TextStyle(color: colorZircon),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "R\$ ${totalBalance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: colorCyanBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),

                          ),

                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Saldo disponível",
                            style: TextStyle(color: colorZircon),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "R\$ ${availableBalance.toStringAsFixed(2)}",
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

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorCyanBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Valor do portifólio",
                            style: TextStyle(color: colorZircon),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "R\$ ${portfolioValue.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),

                          ),
                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Resultado total",
                            style: TextStyle(color: colorZircon),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "+R\$ ${profit.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),

                          ),
                          Text(
                            "+${profitPercentage.toStringAsFixed(2)}%",
                            style: const TextStyle(
                              color: Colors.green,
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
                    final newBalance = availableBalance + 10;
                    await FirebaseFirestore.instance
                        .collection('wallets')// Verificar no Firebase a colletion e campo
                        .doc(user!.uid)
                        .update({'availableBalance': newBalance});
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: colorVioletBlue,
        unselectedItemColor: colorZircon,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: "Investimentos"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Configurações"),
        ],
      ),
    );
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WalletPage(),
    );
    
  }
}
