import 'package:flutter/material.dart';
import '../models/startup.dart';
import '../services/startup_service.dart';
import '../widgets/startup_card.dart';

class CatalogoStartupsScreen extends StatefulWidget {
  const CatalogoStartupsScreen({super.key});

  @override
  State<CatalogoStartupsScreen> createState() => _CatalogoStartupsScreenState();
}

class _CatalogoStartupsScreenState extends State<CatalogoStartupsScreen> {
  final StartupService _service = StartupService();

  String _filtroTexto = '';
  String _filtroEstagio = 'Todos'; // Controla os botões

  final List<String> _estagios = [
    'Todos',
    'Nova',
    'Em operação',
    'Em expansão',
  ];

  // Função que aplica os dois filtros simultaneamente
  List<Startup> _filtrarStartups(List<Startup> startups) {
    return startups.where((startup) {
      final matchTexto =
          _filtroTexto.isEmpty ||
          startup.name.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          startup.sector.toLowerCase().contains(_filtroTexto.toLowerCase());

      final matchEstagio =
          _filtroEstagio == 'Todos' ||
          startup.stage.toLowerCase() == _filtroEstagio.toLowerCase();

      return matchTexto && matchEstagio;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        title: const Text('Catálogo de Startups'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3A1C71),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Campo de busca por texto
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Buscar por nome ou setor...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6A4CFF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filtroTexto = value;
                });
              },
            ),
          ),

          // Botões de Filtro (Nova, Em operação, Em expansão)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _estagios.length,
              itemBuilder: (context, index) {
                final estagio = _estagios[index];
                final isSelected = _filtroEstagio == estagio;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(estagio),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6A4CFF),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _filtroEstagio = estagio;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Lista de Startups conectada direto ao Firebase (StreamBuilder)
          Expanded(
            child: StreamBuilder<List<Startup>>(
              stream: _service.getStartups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6A4CFF)),
                  );
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
                    child: Text(
                      'Nenhuma startup encontrada.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: startupsFiltradas.length,
                  itemBuilder: (context, index) {
                    final startup = startupsFiltradas[index];

                    return StartupCard(
                      startup: startup,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Você clicou em ${startup.name}'),
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
