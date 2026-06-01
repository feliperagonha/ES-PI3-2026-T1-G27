// Felipe Ragonha
// RA: 24023900

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'catalogo_startups_screen.dart';
import 'mercado_screen.dart';
import 'profile_screen.dart';
import 'wallet_page.dart';

const _purple900 = Color(0xFF3A1C71);
const _purple600 = Color(0xFF6A4CFF);
const _purple100 = Color(0xFFEDE7FF);
const _bg = Color(0xFFF1F1F1);
const _textSecondary = Color(0xFF6B7280);

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  int _mercadoRefreshTick = 0;

  static const List<Widget> _screens = [
    TokenDashboardScreen(),
    CatalogoStartupsScreen(),
    WalletPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;

      if (index == 2) {
        _mercadoRefreshTick++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _screens[0],
          _screens[1],
          MercadoScreen(refreshTick: _mercadoRefreshTick),
          _screens[2],
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _NavItem(
              index: 0,
              currentIndex: _currentIndex,
              icon: Icons.home_outlined,
              iconSelected: Icons.home_rounded,
              label: 'Home',
              onTap: _selectTab,
            ),
            _NavItem(
              index: 1,
              currentIndex: _currentIndex,
              icon: Icons.explore_outlined,
              iconSelected: Icons.explore_rounded,
              label: 'Catalogo',
              onTap: _selectTab,
            ),
            _NavItem(
              index: 2,
              currentIndex: _currentIndex,
              icon: Icons.storefront_outlined,
              iconSelected: Icons.storefront_rounded,
              label: 'Balcao',
              onTap: _selectTab,
            ),
            _NavItem(
              index: 3,
              currentIndex: _currentIndex,
              icon: Icons.account_balance_wallet_outlined,
              iconSelected: Icons.account_balance_wallet_rounded,
              label: 'Carteira',
              onTap: _selectTab,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData iconSelected;
  final String label;
  final void Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? _purple100 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? iconSelected : icon,
                size: 22,
                color: isSelected ? _purple600 : _textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _purple600 : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TokenDashboardScreen extends StatefulWidget {
  const TokenDashboardScreen({super.key});

  @override
  State<TokenDashboardScreen> createState() => _TokenDashboardScreenState();
}

class _TokenDashboardScreenState extends State<TokenDashboardScreen> {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  late Future<List<_DashboardPosition>> _positionsFuture;
  Future<List<_ValuationPoint>>? _historyFuture;

  _DashboardPosition? _selectedPosition;
  String _period = 'monthly';

  static const Map<String, String> _periodLabels = {
    'daily': 'Dia',
    'weekly': 'Semana',
    'monthly': 'Mes',
    'sixMonths': '6 meses',
    'ytd': 'YTD',
  };

  @override
  void initState() {
    super.initState();
    _positionsFuture = _loadPositions();
  }

  Future<List<_DashboardPosition>> _loadPositions() async {
    final positionsResult = await _functions
        .httpsCallable('listInvestorPositions')
        .call();
    final startupsResult = await _functions
        .httpsCallable('listStartups')
        .call();

    final positionsResponse = Map<String, dynamic>.from(positionsResult.data);
    final startupsResponse = Map<String, dynamic>.from(startupsResult.data);

    final positionsData = List<Map<String, dynamic>>.from(
      ((positionsResponse['data'] ?? []) as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    final startupsData = List<Map<String, dynamic>>.from(
      ((startupsResponse['data'] ?? []) as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    final positionsByStartupId = {
      for (final position in positionsData.map(_DashboardPosition.fromJson))
        position.startupId: position,
    };

    final positions = startupsData
        .map((startup) {
          final startupId = startup['id']?.toString() ?? '';
          return positionsByStartupId[startupId] ??
              _DashboardPosition.fromStartupJson(startup);
        })
        .where((position) => position.startupId.isNotEmpty)
        .toList();

    for (final position in positionsByStartupId.values) {
      final alreadyListed = positions.any(
        (item) => item.startupId == position.startupId,
      );

      if (!alreadyListed) {
        positions.add(position);
      }
    }

    final selectedStillExists = positions.any(
      (position) => position.startupId == _selectedPosition?.startupId,
    );

    if (positions.isNotEmpty &&
        (_selectedPosition == null || !selectedStillExists)) {
      _selectedPosition = positions.first;
      _historyFuture = _loadHistory(positions.first.startupId);
    }

    return positions;
  }

  Future<List<_ValuationPoint>> _loadHistory(String startupId) async {
    final result = await _functions
        .httpsCallable('getTokenValuationHistory')
        .call({'startupId': startupId, 'period': _period});

    final response = Map<String, dynamic>.from(result.data);
    final data = List<Map<String, dynamic>>.from(
      ((response['data'] ?? []) as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    return data.map(_ValuationPoint.fromJson).toList();
  }

  void _selectPosition(_DashboardPosition? position) {
    if (position == null) {
      return;
    }

    setState(() {
      _selectedPosition = position;
      _historyFuture = _loadHistory(position.startupId);
    });
  }

  void _selectPeriod(String period) {
    final position = _selectedPosition;

    if (position == null) {
      return;
    }

    setState(() {
      _period = period;
      _historyFuture = _loadHistory(position.startupId);
    });
  }

  void _refreshDashboard() {
    setState(() {
      _positionsFuture = _loadPositions();
      final position = _selectedPosition;
      if (position != null) {
        _historyFuture = _loadHistory(position.startupId);
      }
    });
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatPercent(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: _purple900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: FutureBuilder<List<_DashboardPosition>>(
        future: _positionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple600),
            );
          }

          if (snapshot.hasError) {
            return _DashboardMessage(
              icon: Icons.error_outline_rounded,
              title: 'Nao foi possivel carregar o dashboard',
              message: snapshot.error.toString(),
            );
          }

          final positions = snapshot.data ?? [];

          if (positions.isEmpty) {
            return const _DashboardMessage(
              icon: Icons.query_stats_rounded,
              title: 'Sem tokens na carteira',
              message:
                  'Compre tokens de uma startup para acompanhar a valorizacao.',
            );
          }

          final selected = _selectedPosition ?? positions.first;
          final historyFuture =
              _historyFuture ?? _loadHistory(selected.startupId);

          return RefreshIndicator(
            color: _purple600,
            onRefresh: () async {
              _refreshDashboard();
              await _positionsFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DashboardHeader(
                  positions: positions,
                  selected: selected,
                  onChanged: _selectPosition,
                ),
                const SizedBox(height: 16),
                _PeriodSelector(
                  periodLabels: _periodLabels,
                  selectedPeriod: _period,
                  onSelected: _selectPeriod,
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<_ValuationPoint>>(
                  future: historyFuture,
                  builder: (context, historySnapshot) {
                    if (historySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const _DashboardCard(
                        child: SizedBox(
                          height: 260,
                          child: Center(
                            child: CircularProgressIndicator(color: _purple600),
                          ),
                        ),
                      );
                    }

                    if (historySnapshot.hasError) {
                      return _DashboardCard(
                        child: Text(
                          'Erro ao carregar valorizacao: ${historySnapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final history = historySnapshot.data ?? [];

                    if (history.isEmpty) {
                      return const _DashboardCard(
                        child: SizedBox(
                          height: 220,
                          child: Center(
                            child: Text(
                              'Ainda nao ha transacoes suficientes para este periodo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _textSecondary),
                            ),
                          ),
                        ),
                      );
                    }

                    final last = history.last;

                    return Column(
                      children: [
                        _DashboardCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricBlock(
                                      label: 'Preco medio',
                                      value: _formatMoney(last.price),
                                    ),
                                  ),
                                  Expanded(
                                    child: _MetricBlock(
                                      label: 'Variacao',
                                      value: _formatPercent(
                                        last.variationPercent,
                                      ),
                                      color: last.variationPercent >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      align: CrossAxisAlignment.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 190,
                                child: CustomPaint(
                                  painter: _ValuationChartPainter(history),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DashboardCard(
                          child: Column(
                            children: [
                              _InfoLine(
                                label: 'Tokens na carteira',
                                value: '${selected.quantity}',
                              ),
                              const Divider(height: 20),
                              _InfoLine(
                                label: 'Disponiveis',
                                value: '${selected.availableQuantity}',
                              ),
                              const Divider(height: 20),
                              _InfoLine(
                                label: 'Em oferta',
                                value: '${selected.reservedQuantity}',
                              ),
                              const Divider(height: 20),
                              _InfoLine(
                                label: 'Preco atual',
                                value: _formatMoney(selected.currentPrice),
                              ),
                              const Divider(height: 20),
                              _InfoLine(
                                label: 'Valor atual',
                                value: _formatMoney(selected.currentValue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardPosition {
  final String startupId;
  final String startupName;
  final int quantity;
  final int availableQuantity;
  final int reservedQuantity;
  final double currentPrice;
  final double currentValue;

  const _DashboardPosition({
    required this.startupId,
    required this.startupName,
    required this.quantity,
    required this.availableQuantity,
    required this.reservedQuantity,
    required this.currentPrice,
    required this.currentValue,
  });

  factory _DashboardPosition.fromJson(Map<String, dynamic> json) {
    final currentPrice = (json['currentPrice'] as num?)?.toDouble() ?? 0;
    final quantity = (json['quantity'] as num?)?.toInt() ?? 0;

    return _DashboardPosition(
      startupId: json['startupId']?.toString() ?? '',
      startupName: json['startupName']?.toString() ?? 'Startup',
      quantity: quantity,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      reservedQuantity: (json['reservedQuantity'] as num?)?.toInt() ?? 0,
      currentPrice: currentPrice,
      currentValue:
          (json['currentValue'] as num?)?.toDouble() ?? quantity * currentPrice,
    );
  }

  factory _DashboardPosition.fromStartupJson(Map<String, dynamic> json) {
    final currentPrice = (json['currentPrice'] as num?)?.toDouble() ?? 0;

    return _DashboardPosition(
      startupId: json['id']?.toString() ?? '',
      startupName: json['name']?.toString() ?? 'Startup',
      quantity: 0,
      availableQuantity: 0,
      reservedQuantity: 0,
      currentPrice: currentPrice,
      currentValue: 0,
    );
  }
}

class _ValuationPoint {
  final String date;
  final double price;
  final double variationPercent;
  final int volume;

  const _ValuationPoint({
    required this.date,
    required this.price,
    required this.variationPercent,
    required this.volume,
  });

  factory _ValuationPoint.fromJson(Map<String, dynamic> json) {
    return _ValuationPoint(
      date: json['date']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      variationPercent: (json['variationPercent'] as num?)?.toDouble() ?? 0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final List<_DashboardPosition> positions;
  final _DashboardPosition selected;
  final ValueChanged<_DashboardPosition?> onChanged;

  const _DashboardHeader({
    required this.positions,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DashboardPosition>(
          value: positions.firstWhere(
            (position) => position.startupId == selected.startupId,
            orElse: () => positions.first,
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: positions.map((position) {
            return DropdownMenuItem<_DashboardPosition>(
              value: position,
              child: Text(
                position.startupName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final Map<String, String> periodLabels;
  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  const _PeriodSelector({
    required this.periodLabels,
    required this.selectedPeriod,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: periodLabels.entries.map((entry) {
          final selected = entry.key == selectedPeriod;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              selectedColor: _purple600,
              labelStyle: TextStyle(
                color: selected ? Colors.white : _textSecondary,
                fontWeight: FontWeight.w700,
              ),
              onSelected: (_) => onSelected(entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;

  const _DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  const _MetricBlock({
    required this.label,
    required this.value,
    this.color = const Color(0xFF1A1A2E),
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: _textSecondary)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: _purple600),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuationChartPainter extends CustomPainter {
  final List<_ValuationPoint> points;

  const _ValuationChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = _purple600
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = _purple600.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = _purple600
      ..style = PaintingStyle.fill;

    final minPrice = points
        .map((point) => point.price)
        .reduce((value, element) => value < element ? value : element);
    final maxPrice = points
        .map((point) => point.price)
        .reduce((value, element) => value > element ? value : element);
    final range = maxPrice - minPrice;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointOffset(int index, _ValuationPoint point) {
      final x = points.length == 1
          ? size.width / 2
          : (size.width / (points.length - 1)) * index;
      final normalized = range == 0 ? 0.5 : (point.price - minPrice) / range;
      final y = size.height - (normalized * size.height);

      return Offset(x, y);
    }

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final offset = pointOffset(i, points[i]);

      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
        fillPath.moveTo(offset.dx, size.height);
        fillPath.lineTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
        fillPath.lineTo(offset.dx, offset.dy);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(pointOffset(i, points[i]), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ValuationChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
