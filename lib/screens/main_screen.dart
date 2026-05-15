// Felipe Ragonha
// RA: 24023900

// Juliano Perusso
// RA: 24023434

import 'package:flutter/material.dart';
import 'catalogo_startups_screen.dart';
import 'mercado_screen.dart';
import 'wallet_page.dart';

const _purple900 = Color(0xFF3A1C71);
const _purple600 = Color(0xFF6A4CFF);
const _purple100 = Color(0xFFEDE7FF);
const _bg = Color(0xFFF1F1F1);
const _textSecondary = Color(0xFF6B7280);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Mantém as telas vivas ao trocar de aba (não recarrega toda vez)
  static const List<Widget> _screens = [
    _DashboardPlaceholder(),       // 0 — Home / Dashboard (a fazer)
    CatalogoStartupsScreen(),      // 1 — Catálogo
    MercadoScreen(),               // 2 — Balcão de Tokens
    WalletPage(),                  // 3 — Carteira
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantém o estado de cada tela ao navegar
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
              onTap: (i) => setState(() => _currentIndex = i),
            ),
            _NavItem(
              index: 1,
              currentIndex: _currentIndex,
              icon: Icons.explore_outlined,
              iconSelected: Icons.explore_rounded,
              label: 'Catálogo',
              onTap: (i) => setState(() => _currentIndex = i),
            ),
            _NavItem(
              index: 2,
              currentIndex: _currentIndex,
              icon: Icons.storefront_outlined,
              iconSelected: Icons.storefront_rounded,
              label: 'Balcão',
              onTap: (i) => setState(() => _currentIndex = i),
            ),
            _NavItem(
              index: 3,
              currentIndex: _currentIndex,
              icon: Icons.account_balance_wallet_outlined,
              iconSelected: Icons.account_balance_wallet_rounded,
              label: 'Carteira',
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ],
        ),
      ),
    );
  }
}

// Item individual da nav bar

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

// Placeholder do Dashboard (a implementar)

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

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
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _purple100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                size: 48,
                color: _purple600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Em construção — em breve aqui!',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
