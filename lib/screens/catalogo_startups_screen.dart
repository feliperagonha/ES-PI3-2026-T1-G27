import 'package:flutter/material.dart';
import '../models/startup.dart';
import '../repositories/startup_repository.dart';
import '../widgets/startup_card.dart';
import 'startup_detail_screen.dart';

class CatalogoStartupsScreen extends StatefulWidget {
  const CatalogoStartupsScreen({super.key});

  @override
  State<CatalogoStartupsScreen> createState() => _CatalogoStartupsScreenState();
}

class _CatalogoStartupsScreenState extends State<CatalogoStartupsScreen> {
  final StartupRepository _repository = StartupRepository();
  String _filtroBusca = '';

  List<Startup> _filtrarStartups(List<Startup> startups) {
    if (_filtroBusca.isEmpty) return startups;

    return startups.where((startup) {
      return startup.name.toLowerCase().contains(_filtroBusca.toLowerCase()) ||
          startup.sector.toLowerCase().contains(_filtroBusca.toLowerCase()) ||
          startup.stage.toLowerCase().contains(_filtroBusca.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Startups'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nome, setor ou estágio',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filtroBusca = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Startup>>(
              stream: _repository.getStartups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar startups: ${snapshot.error}'),
                  );
                }

                final startups = snapshot.data ?? [];
                final startupsFiltradas = _filtrarStartups(startups);

                if (startupsFiltradas.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma startup encontrada.'),
                  );
                }

                return ListView.builder(
                  itemCount: startupsFiltradas.length,
                  itemBuilder: (context, index) {
                    final startup = startupsFiltradas[index];

                    return StartupCard(
                      startup: startup,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StartupDetailScreen(startup: startup),
                              ),
                            );
                          },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}